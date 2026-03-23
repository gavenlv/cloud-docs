# 使用Sentinel进行策略检查

# policy/sentinel.hcl
import "tfplan"

main = rule {
  all tfplan.resource_changes as _, changes {
    validate_instance_type(changes)
  }
}

validate_instance_type = func(changes) {
  changes.change.after.type is "google_compute_instance" and
  changes.change.after.machine_type in ["e2-medium", "e2-highcpu-4"]
}