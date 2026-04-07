package controllers

import (
	"crypto/rand"
	"fmt"
	"math/big"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	pgv1 "github.com/example/postgresql-operator/api/v1"
)

func generatePassword() string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	result := make([]byte, 24)
	for i := range result {
		n, _ := rand.Int(rand.Reader, big.NewInt(int64(len(charset))))
		result[i] = charset[n.Int64()]
	}
	return string(result)
}

func getPodRole(pod corev1.Pod) string {
	if role, ok := pod.Labels["role"]; ok {
		return role
	}
	return "unknown"
}

func findPrimary(pods []corev1.Pod) string {
	for _, pod := range pods {
		if pod.Labels["role"] == "primary" {
			for _, cond := range pod.Status.Conditions {
				if cond.Type == corev1.PodReady && cond.Status == corev1.ConditionTrue {
					return pod.Name
				}
			}
		}
	}
	return ""
}

func determinePhase(sts *appsv1.StatefulSet, readyReplicas, desired int32) string {
	if sts == nil {
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
	newCondition := metav1.Condition{
		Type:               condType,
		Status:             metav1.ConditionStatus(fmt.Sprintf("%v", statusBool)),
		Reason:             fmt.Sprintf("Condition%s", condType),
		Message:            message,
		LastTransitionTime: now,
		ObservedGeneration: 0,
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

func (r *PostgresClusterReconciler) updateErrorStatus(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
	err error,
) (ctrl.Result, error) {
	logger.Error(err, "Error reconciling PostgresCluster")
	oldPhase := cluster.Status.Phase
	cluster.Status.Phase = "Error"
	setCondition(&cluster.Status, "Ready", false, err.Error())
	if oldPhase != cluster.Status.Phase {
		if updateErr := r.Status().Update(ctx, cluster); updateErr != nil {
			return ctrl.Result{}, updateErr
		}
	}
	return ctrl.Result{RequeueAfter: requeueAfter}, nil
}

func (r *PostgresClusterReconciler) performFinalBackup(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) error {
	logger.Info("Performing final backup before deletion")
	return nil
}

func (r *PostgresClusterReconciler) reconcilePgBouncer(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) error {
	logger.Info("Reconciling PgBouncer")
	return nil
}
