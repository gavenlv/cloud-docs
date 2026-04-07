package v1

import (
	"k8s.io/apimachinery/pkg/runtime"
)

func (in *PostgresCluster) DeepCopyInto(out *PostgresCluster) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ObjectMeta.DeepCopyInto(&out.ObjectMeta)
	in.Spec.DeepCopyInto(&out.Spec)
	in.Status.DeepCopyInto(&out.Status)
}

func (in *PostgresCluster) DeepCopy() *PostgresCluster {
	if in == nil {
		return nil
	}
	out := new(PostgresCluster)
	in.DeepCopyInto(out)
	return out
}

func (in *PostgresCluster) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

func (in *PostgresClusterList) DeepCopyInto(out *PostgresClusterList) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ListMeta.DeepCopyInto(&out.ListMeta)
	if in.Items != nil {
		in, out := &in.Items, &out.Items
		*out = make([]PostgresCluster, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
}

func (in *PostgresClusterList) DeepCopy() *PostgresClusterList {
	if in == nil {
		return nil
	}
	out := new(PostgresClusterList)
	in.DeepCopyInto(out)
	return out
}

func (in *PostgresClusterList) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

func (in *PostgresClusterSpec) DeepCopyInto(out *PostgresClusterSpec) {
	*out = *in
	in.Storage.DeepCopyInto(&out.Storage)
	in.Resources.DeepCopyInto(&out.Resources)
	out.HighAvailability = in.HighAvailability
	out.Backup = in.Backup
	if in.ConnectionPool != nil {
		in, out := &in.ConnectionPool, &out.ConnectionPool
		*out = new(ConnectionPoolSpec)
		(*in).DeepCopyInto(*out)
	}
	if in.Parameters != nil {
		in, out := &in.Parameters, &out.Parameters
		*out = make(map[string]string, len(*in))
		for key, val := range *in {
			(*out)[key] = val
		}
	}
}

func (in *PostgresClusterSpec) DeepCopy() *PostgresClusterSpec {
	if in == nil {
		return nil
	}
	out := new(PostgresClusterSpec)
	in.DeepCopyInto(out)
	return out
}

func (in *StorageSpec) DeepCopyInto(out *StorageSpec) {
	*out = *in
}

func (in *StorageSpec) DeepCopy() *StorageSpec {
	if in == nil {
		return nil
	}
	out := new(StorageSpec)
	in.DeepCopyInto(out)
	return out
}

func (in *HighAvailabilitySpec) DeepCopyInto(out *HighAvailabilitySpec) {
	*out = *in
}

func (in *HighAvailabilitySpec) DeepCopy() *HighAvailabilitySpec {
	if in == nil {
		return nil
	}
	out := new(HighAvailabilitySpec)
	in.DeepCopyInto(out)
	return out
}

func (in *BackupSpec) DeepCopyInto(out *BackupSpec) {
	*out = *in
}

func (in *BackupSpec) DeepCopy() *BackupSpec {
	if in == nil {
		return nil
	}
	out := new(BackupSpec)
	in.DeepCopyInto(out)
	return out
}

func (in *ConnectionPoolSpec) DeepCopyInto(out *ConnectionPoolSpec) {
	*out = *in
	in.Resources.DeepCopyInto(&out.Resources)
}

func (in *ConnectionPoolSpec) DeepCopy() *ConnectionPoolSpec {
	if in == nil {
		return nil
	}
	out := new(ConnectionPoolSpec)
	in.DeepCopyInto(out)
	return out
}

func (in *PostgresClusterStatus) DeepCopyInto(out *PostgresClusterStatus) {
	*out = *in
	if in.Instances != nil {
		in, out := &in.Instances, &out.Instances
		*out = make([]InstanceStatus, len(*in))
		copy(*out, *in)
	}
	if in.Conditions != nil {
		in, out := &in.Conditions, &out.Conditions
		*out = make([]metav1.Condition, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
}

func (in *PostgresClusterStatus) DeepCopy() *PostgresClusterStatus {
	if in == nil {
		return nil
	}
	out := new(PostgresClusterStatus)
	in.DeepCopyInto(out)
	return out
}

func (in *InstanceStatus) DeepCopyInto(out *InstanceStatus) {
	*out = *in
}

func (in *InstanceStatus) DeepCopy() *InstanceStatus {
	if in == nil {
		return nil
	}
	out := new(InstanceStatus)
	in.DeepCopyInto(out)
	return out
}
