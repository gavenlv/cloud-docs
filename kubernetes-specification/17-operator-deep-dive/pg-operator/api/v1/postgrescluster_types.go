package v1

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type PostgresClusterSpec struct {
	Instances int32 `json:"instances"`

	PostgreSQLVersion string `json:"postgresqlVersion"`

	Storage StorageSpec `json:"storage"`

	Resources corev1.ResourceRequirements `json:"resources,omitempty"`

	HighAvailability HighAvailabilitySpec `json:"highAvailability,omitempty"`

	Backup BackupSpec `json:"backup,omitempty"`

	ConnectionPool *ConnectionPoolSpec `json:"connectionPool,omitempty"`

	Parameters map[string]string `json:"parameters,omitempty"`

	Database string `json:"database,omitempty"`
}

type StorageSpec struct {
	Size         string `json:"size"`
	StorageClass string `json:"storageClass,omitempty"`
}

type HighAvailabilitySpec struct {
	Enabled         bool  `json:"enabled"`
	FailoverTimeout int32 `json:"failoverTimeout,omitempty"`
}

type BackupSpec struct {
	Enabled     bool   `json:"enabled"`
	Schedule    string `json:"schedule,omitempty"`
	Retention   int32  `json:"retention,omitempty"`
	Destination string `json:"destination,omitempty"`
}

type ConnectionPoolSpec struct {
	Enabled        bool                      `json:"enabled"`
	MinConnections int32                     `json:"minConnections,omitempty"`
	MaxClientConn  int32                     `json:"maxClientConn,omitempty"`
	Mode           string                    `json:"mode,omitempty"`
	Resources      corev1.ResourceRequirements `json:"resources,omitempty"`
}

type PostgresClusterStatus struct {
	Phase string `json:"phase"`

	ReadyReplicas int32 `json:"readyReplicas"`

	CurrentPrimary string `json:"currentPrimary"`

	Instances []InstanceStatus `json:"instances,omitempty"`

	Conditions []metav1.Condition `json:"conditions,omitempty"`
}

type InstanceStatus struct {
	Name    string `json:"name"`
	Role    string `json:"role"`
	Ready   bool   `json:"ready"`
	PodName string `json:"podName"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:shortName=pg
// +kubebuilder:printcolumn:name="Instances",type="integer",JSONPath=".spec.instances",description="Number of instances"
// +kubebuilder:printcolumn:name="Phase",type="string",JSONPath=".status.phase",description="Cluster phase"
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"

type PostgresCluster struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   PostgresClusterSpec   `json:"spec,omitempty"`
	Status PostgresClusterStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

type PostgresClusterList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []PostgresCluster `json:"items"`
}

func init() {
	SchemeBuilder.Register(&PostgresCluster{}, &PostgresClusterList{})
}
