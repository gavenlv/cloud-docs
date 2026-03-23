# 1. 创建Workload Identity Pool
gcloud iam workload-identity-pools create github-actions \
  --location="global" \
  --display-name="GitHub Actions Pool"

# 2. 创建Workload Identity Provider
gcloud iam workload-identity-pools providers create github-actions-provider \
  --workload-identity-pool="github-actions" \
  --location="global" \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub"

# 3. 配置Provider属性映射
gcloud iam workload-identity-pools providers update-attribute-condition github-actions-provider \
  --workload-identity-pool="github-actions" \
  --location="global" \
  --attribute-condition="attribute.repository==my-org/my-repo"

# 4. 授予服务账号Impersonation权限
gcloud iam service-accounts add-iam-policy-binding terraform@my-project-id.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/my-project-id/locations/global/workloadIdentityPools/github-actions/attribute.repository/my-org/my-repo"