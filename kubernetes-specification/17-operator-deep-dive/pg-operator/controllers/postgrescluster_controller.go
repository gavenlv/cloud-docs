package controllers

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/util/intstr"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"

	pgv1 "github.com/example/postgresql-operator/api/v1"
)

const (
	finalizerName = "postgrescluster.k8s.example.com/finalizer"
	requeueAfter  = 30 * time.Second
)

type PostgresClusterReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

func (r *PostgresClusterReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	var cluster pgv1.PostgresCluster
	if err := r.Get(ctx, req.NamespacedName, &cluster); err != nil {
		if errors.IsNotFound(err) {
			logger.Info("PostgresCluster resource not found. Ignoring since object must be deleted")
			return ctrl.Result{}, nil
		}
		logger.Error(err, "Failed to get PostgresCluster")
		return ctrl.Result{}, err
	}

	if !cluster.ObjectMeta.DeletionTimestamp.IsZero() {
		return r.handleDeletion(ctx, logger, &cluster)
	}

	if !controllerutil.ContainsFinalizer(&cluster, finalizerName) {
		controllerutil.AddFinalizer(&cluster, finalizerName)
		if err := r.Update(ctx, &cluster); err != nil {
			logger.Error(err, "Failed to add finalizer")
			return ctrl.Result{}, err
		}
		return ctrl.Result{Requeue: true}, nil
	}

	sts, err := r.reconcileStatefulSet(ctx, logger, &cluster)
	if err != nil {
		logger.Error(err, "Failed to reconcile StatefulSet")
		return r.updateErrorStatus(ctx, logger, &cluster, err)
	}

	if err := r.reconcileServices(ctx, logger, &cluster); err != nil {
		logger.Error(err, "Failed to reconcile Services")
		return r.updateErrorStatus(ctx, logger, &cluster, err)
	}

	if err := r.reconcileConfigMap(ctx, logger, &cluster); err != nil {
		logger.Error(err, "Failed to reconcile ConfigMap")
		return r.updateErrorStatus(ctx, logger, &cluster, err)
	}

	if err := r.reconcileSecret(ctx, logger, &cluster); err != nil {
		logger.Error(err, "Failed to reconcile Secret")
		return r.updateErrorStatus(ctx, logger, &cluster, err)
	}

	if err := r.updateStatus(ctx, logger, &cluster, sts); err != nil {
		logger.Error(err, "Failed to update status")
		return ctrl.Result{}, err
	}

	logger.Info("Reconcile completed successfully", "phase", cluster.Status.Phase)
	return ctrl.Result{RequeueAfter: requeueAfter}, nil
}

func (r *PostgresClusterReconciler) reconcileStatefulSet(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) (*appsv1.StatefulSet, error) {

	sts := &appsv1.StatefulSet{}
	err := r.Get(ctx, types.NamespacedName{
		Name:      cluster.Name,
		Namespace: cluster.Namespace,
	}, sts)

	if errors.IsNotFound(err) {
		logger.Info("Creating new StatefulSet")
		sts = r.buildStatefulSet(cluster)
		if err := r.Create(ctx, sts); err != nil {
			return nil, fmt.Errorf("failed to create StatefulSet: %w", err)
		}
		return sts, nil
	} else if err != nil {
		return nil, err
	}

	desiredSts := r.buildStatefulSet(cluster)
	needsUpdate := false

	if *sts.Spec.Replicas != *desiredSts.Spec.Replicas {
		sts.Spec.Replicas = desiredSts.Spec.Replicas
		needsUpdate = true
	}

	currentImage := sts.Spec.Template.Spec.Containers[0].Image
	desiredImage := fmt.Sprintf("postgres:%s", cluster.Spec.PostgreSQLVersion)
	if currentImage != desiredImage {
		sts.Spec.Template.Spec.Containers[0].Image = desiredImage
		needsUpdate = true
	}

	if needsUpdate {
		logger.Info("Updating StatefulSet")
		if err := r.Update(ctx, sts); err != nil {
			return nil, fmt.Errorf("failed to update StatefulSet: %w", err)
		}
	}

	return sts, nil
}

func (r *PostgresClusterReconciler) buildStatefulSet(cluster *pgv1.PostgresCluster) *appsv1.StatefulSet {
	replicas := cluster.Spec.Instances
	labels := map[string]string{
		"app":        "postgresql",
		"cluster":    cluster.Name,
		"managed-by": "postgres-operator",
	}

	sts := &appsv1.StatefulSet{
		ObjectMeta: metav1.ObjectMeta{
			Name:      cluster.Name,
			Namespace: cluster.Namespace,
			Labels:    labels,
		},
		Spec: appsv1.StatefulSetSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: labels,
			},
			ServiceName: cluster.Name + "-headless",
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: labels,
					Annotations: map[string]string{
						"prometheus.io/scrape": "true",
						"prometheus.io/port":   "9187",
					},
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:  "postgres",
							Image: fmt.Sprintf("postgres:%s", cluster.Spec.PostgreSQLVersion),
							Env: []corev1.EnvVar{
								{Name: "PGDATA", Value: "/var/lib/postgresql/data/pgdata"},
								{Name: "POSTGRES_DB", Value: cluster.Spec.Database},
								{
									Name: "POSTGRES_PASSWORD",
									ValueFrom: &corev1.EnvVarSource{
										SecretKeyRef: &corev1.SecretKeySelector{
											LocalObjectReference: corev1.LocalObjectReference{
												Name: cluster.Name + "-secret",
											},
											Key: "postgres-password",
										},
									},
								},
								{
									Name: "POD_NAME",
									ValueFrom: &corev1.EnvVarSource{
										FieldRef: &corev1.ObjectFieldSelector{
											FieldPath: "metadata.name",
										},
									},
								},
								{Name: "CLUSTER_NAME", Value: cluster.Name},
							},
							Ports: []corev1.ContainerPort{
								{ContainerPort: 5432, Name: "postgresql"},
							},
							VolumeMounts: []corev1.VolumeMount{
								{Name: "data", MountPath: "/var/lib/postgresql/data"},
								{Name: "config", MountPath: "/etc/postgresql/conf.d", ReadOnly: true},
							},
							LivenessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									TCPSocket: &corev1.TCPSocketAction{
										Port: intstr.FromInt(5432),
									},
								},
								InitialDelaySeconds: 30,
								PeriodSeconds:       10,
								TimeoutSeconds:      5,
								FailureThreshold:    3,
							},
							ReadinessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									Exec: &corev1.ExecAction{
										Command: []string{"pg_isready", "-U", "postgres", "-h", "localhost"},
									},
								},
								InitialDelaySeconds: 5,
								PeriodSeconds:       5,
								TimeoutSeconds:      3,
								FailureThreshold:    3,
							},
							Resources: cluster.Spec.Resources,
						},
					},
					Volumes: []corev1.Volume{
						{
							Name: "config",
							VolumeSource: corev1.VolumeSource{
								ConfigMap: &corev1.ConfigMapVolumeSource{
									LocalObjectReference: corev1.LocalObjectReference{
										Name: cluster.Name + "-config",
									},
								},
							},
						},
					},
				},
			},
			VolumeClaimTemplates: []corev1.PersistentVolumeClaim{
				{
					ObjectMeta: metav1.ObjectMeta{
						Name:   "data",
						Labels: labels,
					},
					Spec: corev1.PersistentVolumeClaimSpec{
						AccessModes: []corev1.PersistentVolumeAccessMode{
							corev1.ReadWriteOnce,
						},
						Resources: corev1.VolumeResourceRequirements{
							Requests: corev1.ResourceList{
								corev1.ResourceStorage: resource.MustParse(cluster.Spec.Storage.Size),
							},
						},
						StorageClassName: func() *string {
							if cluster.Spec.Storage.StorageClass != "" {
								return &cluster.Spec.Storage.StorageClass
							}
							return nil
						}(),
					},
				},
			},
		},
	}

	if err := controllerutil.SetControllerReference(cluster, sts, r.Scheme); err != nil {
		return nil
	}
	return sts
}

func (r *PostgresClusterReconciler) reconcileServices(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) error {

	services := []struct {
		name     string
		selector map[string]string
		headless bool
	}{
		{
			name: cluster.Name,
			selector: map[string]string{
				"app":     "postgresql",
				"cluster": cluster.Name,
				"role":    "primary",
			},
			headless: false,
		},
		{
			name: cluster.Name + "-headless",
			selector: map[string]string{
				"app":     "postgresql",
				"cluster": cluster.Name,
			},
			headless: true,
		},
		{
			name: cluster.Name + "-replica",
			selector: map[string]string{
				"app":     "postgresql",
				"cluster": cluster.Name,
				"role":    "replica",
			},
			headless: false,
		},
	}

	for _, svcDef := range services {
		svc := &corev1.Service{}
		err := r.Get(ctx, types.NamespacedName{
			Name:      svcDef.name,
			Namespace: cluster.Namespace,
		}, svc)

		newSvc := &corev1.Service{
			ObjectMeta: metav1.ObjectMeta{
				Name:      svcDef.name,
				Namespace: cluster.Namespace,
				Labels: map[string]string{
					"app":     "postgresql",
					"cluster": cluster.Name,
				},
			},
			Spec: corev1.ServiceSpec{
				Selector: svcDef.selector,
				Ports: []corev1.ServicePort{
					{
						Name:       "postgresql",
						Port:       5432,
						TargetPort: intstr.FromInt(5432),
					},
				},
			},
		}

		if svcDef.headless {
			newSvc.Spec.ClusterIP = corev1.ClusterIPNone
			newSvc.Spec.PublishNotReadyAddresses = true
		}

		if errors.IsNotFound(err) {
			controllerutil.SetControllerReference(cluster, newSvc, r.Scheme)
			if err := r.Create(ctx, newSvc); err != nil {
				return fmt.Errorf("failed to create service %s: %w", svcDef.name, err)
			}
			logger.Info("Created service", "name", svcDef.name)
		} else if err == nil {
			newSvc.ResourceVersion = svc.ResourceVersion
			newSvc.Spec.ClusterIP = svc.Spec.ClusterIP
			if err := r.Update(ctx, newSvc); err != nil {
				return fmt.Errorf("failed to update service %s: %w", svcDef.name, err)
			}
		} else {
			return err
		}
	}
	return nil
}

func (r *PostgresClusterReconciler) reconcileConfigMap(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) error {

	cm := &corev1.ConfigMap{}
	err := r.Get(ctx, types.NamespacedName{
		Name:      cluster.Name + "-config",
		Namespace: cluster.Namespace,
	}, cm)

	defaultParams := map[string]string{
		"max_connections":        "100",
		"shared_buffers":         "256MB",
		"effective_cache_size":   "1GB",
		"maintenance_work_mem":   "64MB",
		"wal_compression":        "on",
		"wal_level":              "replica",
		"max_wal_senders":        "10",
		"hot_standby":            "on",
		"random_page_cost":       "1.1",
		"effective_io_concurrency": "200",
	}

	for k, v := range cluster.Spec.Parameters {
		defaultParams[k] = v
	}

	configContent := "# PostgreSQL Configuration\n"
	configContent += "# Generated by postgresql-operator\n\n"
	for k, v := range defaultParams {
		configContent += fmt.Sprintf("%s = '%s'\n", k, v)
	}

	newCM := &corev1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name:      cluster.Name + "-config",
			Namespace: cluster.Namespace,
			Labels: map[string]string{
				"app":     "postgresql",
				"cluster": cluster.Name,
			},
		},
		Data: map[string]string{
			"postgresql.conf": configContent,
		},
	}

	if errors.IsNotFound(err) {
		controllerutil.SetControllerReference(cluster, newCM, r.Scheme)
		if err := r.Create(ctx, newCM); err != nil {
			return fmt.Errorf("failed to create configmap: %w", err)
		}
		logger.Info("Created ConfigMap")
	} else if err == nil {
		newCM.ResourceVersion = cm.ResourceVersion
		if err := r.Update(ctx, newCM); err != nil {
			return fmt.Errorf("failed to update configmap: %w", err)
		}
	} else {
		return err
	}
	return nil
}

func (r *PostgresClusterReconciler) reconcileSecret(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) error {

	secret := &corev1.Secret{}
	err := r.Get(ctx, types.NamespacedName{
		Name:      cluster.Name + "-secret",
		Namespace: cluster.Namespace,
	}, secret)

	if errors.IsNotFound(err) {
		newSecret := &corev1.Secret{
			ObjectMeta: metav1.ObjectMeta{
				Name:      cluster.Name + "-secret",
				Namespace: cluster.Namespace,
				Labels: map[string]string{
					"app":     "postgresql",
					"cluster": cluster.Name,
				},
			},
			StringData: map[string]string{
				"postgres-password":        generatePassword(24),
				"replication-password":     generatePassword(24),
				"superuser-password":       generatePassword(24),
			},
			Type: corev1.SecretTypeOpaque,
		}

		controllerutil.SetControllerReference(cluster, newSecret, r.Scheme)
		if err := r.Create(ctx, newSecret); err != nil {
			return fmt.Errorf("failed to create secret: %w", err)
		}
		logger.Info("Created Secret with generated passwords")
	} else if err != nil {
		return err
	}

	return nil
}

func (r *PostgresClusterReconciler) updateStatus(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
	sts *appsv1.StatefulSet,
) error {

	podList := &corev1.PodList{}
	if err := r.List(ctx, podList,
		client.InNamespace(cluster.Namespace),
		client.MatchingLabels{"cluster": cluster.Name},
	); err != nil {
		return fmt.Errorf("failed to list pods: %w", err)
	}

	readyCount := int32(0)
	var instances []pgv1.InstanceStatus
	var primaryName string

	for _, pod := range podList.Items {
		isReady := false
		for _, cond := range pod.Status.Conditions {
			if cond.Type == corev1.PodReady && cond.Status == corev1.ConditionTrue {
				isReady = true
				break
			}
		}
		if isReady {
			readyCount++
		}

		role := "replica"
		if pod.Name == cluster.Name+"-0" {
			role = "primary"
			if isReady {
				primaryName = pod.Name
			}
		}

		instances = append(instances, pgv1.InstanceStatus{
			Name:    pod.Name,
			Role:    role,
			Ready:   isReady,
			PodName: pod.Name,
		})
	}

	oldStatus := cluster.Status.DeepCopy()

	cluster.Status.Phase = determinePhase(sts, readyCount, cluster.Spec.Instances)
	cluster.Status.ReadyReplicas = readyCount
	cluster.Status.CurrentPrimary = primaryName
	cluster.Status.Instances = instances

	setCondition(&cluster.Status, "Ready", readyCount >= 1, fmt.Sprintf("%d/%d instances ready", readyCount, cluster.Spec.Instances))
	setCondition(&cluster.Status, "Available", readyCount >= 1, "Cluster is available")

	if oldStatus.Phase != cluster.Status.Phase ||
		oldStatus.ReadyReplicas != cluster.Status.ReadyReplicas ||
		oldStatus.CurrentPrimary != cluster.Status.CurrentPrimary {
		logger.Info("Updating status", "phase", cluster.Status.Phase, "readyReplicas", readyCount)
		return r.Status().Update(ctx, cluster)
	}

	return nil
}

func (r *PostgresClusterReconciler) updateErrorStatus(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
	reconcileErr error,
) (ctrl.Result, error) {
	logger.Error(reconcileErr, "Error reconciling PostgresCluster")

	oldPhase := cluster.Status.Phase
	cluster.Status.Phase = "Error"
	setCondition(&cluster.Status, "Ready", false, reconcileErr.Error())

	if oldPhase != cluster.Status.Phase {
		if updateErr := r.Status().Update(ctx, cluster); updateErr != nil {
			return ctrl.Result{}, updateErr
		}
	}

	return ctrl.Result{RequeueAfter: requeueAfter}, nil
}

func (r *PostgresClusterReconciler) handleDeletion(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) (ctrl.Result, error) {

	if controllerutil.ContainsFinalizer(cluster, finalizerName) {
		logger.Info("Performing cleanup before deletion")

		if cluster.Spec.Backup.Enabled {
			logger.Info("Performing final backup")
		}

		controllerutil.RemoveFinalizer(cluster, finalizerName)
		if err := r.Update(ctx, cluster); err != nil {
			return ctrl.Result{}, err
		}
		logger.Info("Finalizer removed, object can be deleted")
	}

	return ctrl.Result{}, nil
}

func (r *PostgresClusterReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&pgv1.PostgresCluster{}).
		Owns(&appsv1.StatefulSet{}).
		Owns(&corev1.Service{}).
		Owns(&corev1.ConfigMap{}).
		Owns(&corev1.Secret{}).
		Complete(r)
}

func generatePassword(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	result := make([]byte, length)
	for i := range result {
		result[i] = charset[i%len(charset)]
	}
	return string(result)
}

func determinePhase(sts *appsv1.StatefulSet, readyReplicas, desired int32) string {
	if sts == nil {
		return "Creating"
	}
	if sts.Status.Replicas == 0 {
		return "Creating"
	}
	if readyReplicas >= desired && *sts.Spec.Replicas == desired {
		return "Running"
	}
	if readyReplicas < desired || *sts.Spec.Replicas != desired {
		return "Updating"
	}
	return "Pending"
}

func setCondition(status *pgv1.PostgresClusterStatus, condType string, statusBool bool, message string) {
	now := metav1.Now()
	conditionStatus := metav1.ConditionFalse
	if statusBool {
		conditionStatus = metav1.ConditionTrue
	}

	newCondition := metav1.Condition{
		Type:               condType,
		Status:             conditionStatus,
		Reason:             fmt.Sprintf("Condition%s", condType),
		Message:            message,
		LastTransitionTime: now,
	}

	found := false
	for i, c := range status.Conditions {
		if c.Type == condType {
			if c.Status != newCondition.Status {
				newCondition.LastTransitionTime = now
			} else {
				newCondition.LastTransitionTime = c.LastTransitionTime
			}
			status.Conditions[i] = newCondition
			found = true
			break
		}
	}
	if !found {
		status.Conditions = append(status.Conditions, newCondition)
	}
}
