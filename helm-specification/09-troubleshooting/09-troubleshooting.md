# 故障排除

## 9.1 常见错误类型

### 9.1.1 错误分类

```
┌─────────────────────────────────────────────────────────────────┐
│  Helm错误分类                                                    │
└─────────────────────────────────────────────────────────────────┘

1. 模板错误
├── 语法错误
├── 变量未定义
├── 类型错误
├── 函数调用错误
└── 空指针错误

2. Values错误
├── 值不存在
├── 类型不匹配
├── Schema验证失败
└── 合并错误

3. 资源错误
├── 资源已存在
├── 资源不存在
├── 权限不足
└── 配额限制

4. 依赖错误
├── 依赖下载失败
├── 版本不兼容
├── 仓库不可达
└── 依赖循环

5. 网络错误
├── 仓库连接失败
├── Kubernetes API不可达
├── 超时
└── 认证失败
```

---

## 9.2 模板错误排除

### 9.2.1 语法错误

```bash
# 错误示例
Error: parse error in "deployment.yaml": template: mychart/templates/deployment.yaml: unexpected EOF

# 原因：模板语法错误，如{{ }}不成对

# 解决方法：
# 1. 检查模板语法
helm lint ./mychart

# 2. 使用--debug查看详细错误
helm template myapp ./mychart --debug

# 3. 检查常见语法问题
# - {{ 和 }} 是否成对
# - {{- 和 -}} 是否正确使用
# - 引号是否闭合
# - YAML缩进是否正确
```

### 9.2.2 变量未定义

```bash
# 错误示例
Error: INSTALLATION FAILED: unable to build kubernetes objects from release manifest: error validating "": error validating data: ValidationError(Deployment.spec.template.spec.containers[0]): missing required field "image" in io.k8s.api.core.v1.Container

# 或模板错误
Error: template: mychart/templates/deployment.yaml:10:24: executing "mychart/templates/deployment.yaml" at <.Values.image.repository>: map has no entry for key "repository"

# 解决方法：
# 1. 检查values.yaml中是否定义了该值
# 2. 使用default提供默认值
image: "{{ .Values.image.repository | default "nginx" }}"

# 3. 使用条件判断
{{- if .Values.image }}
image: {{ .Values.image.repository }}
{{- end }}

# 4. 使用required确保必需值
image: {{ .Values.image.repository | required "image.repository is required!" }}
```

### 9.2.3 类型错误

```bash
# 错误示例
Error: template: mychart/templates/deployment.yaml: template execution error: wrong type for value; expected string; got int

# 原因：类型不匹配

# 解决方法：
# 1. 使用类型转换函数
port: {{ .Values.service.port | int }}
replicas: {{ .Values.replicaCount | toString | quote }}

# 2. 使用--set-string确保字符串类型
helm install myapp ./mychart --set-string port="8080"

# 3. 在values.yaml中使用正确的类型
# 正确
port: 8080        # 整数
name: "myapp"     # 字符串
enabled: true     # 布尔值
```

### 9.2.4 空指针错误

```bash
# 错误示例
Error: template: mychart/templates/deployment.yaml: nil pointer evaluating interface {}.port

# 原因：访问了不存在的嵌套值

# 解决方法：
# 1. 使用with检查
{{- with .Values.service }}
port: {{ .port }}
{{- end }}

# 2. 使用条件判断
{{- if .Values.service }}
port: {{ .Values.service.port }}
{{- end }}

# 3. 使用default
port: {{ .Values.service.port | default 80 }}
```

---

## 9.3 Values错误排除

### 9.3.1 Schema验证失败

```bash
# 错误示例
Error: values don't meet the specifications of the schema(s) in the following chart(s):
mychart:
- (root): image is required
- service.type: service.type must be one of the following: "ClusterIP", "NodePort", "LoadBalancer"

# 解决方法：
# 1. 检查values.schema.json中的定义
# 2. 确保values.yaml符合schema
# 3. 使用--dry-run验证
helm install myapp ./mychart --dry-run

# 4. 临时跳过schema验证（不推荐）
# 删除或重命名values.schema.json
```

### 9.3.2 Values合并问题

```bash
# 问题：Values没有按预期合并

# 调试方法：
# 1. 查看最终合并的values
helm get values myapp --all

# 2. 使用helm template查看渲染结果
helm template myapp ./mychart -f values.yaml -f values-prod.yaml

# 3. 理解合并规则：
# - 字典：深度合并
# - 列表：完全替换
# - null：删除键

# 示例：
# values.yaml
config:
  database:
    host: localhost
    port: 5432

# values-prod.yaml
config:
  database:
    host: prod-db

# 合并结果
config:
  database:
    host: prod-db    # 覆盖
    port: 5432       # 保留
```

---

## 9.4 资源错误排除

### 9.4.1 资源冲突

```bash
# 错误示例
Error: INSTALLATION FAILED: rendered manifests contain a resource that already exists. Unable to continue with install: existing resource conflict: namespace: default, name: myapp, existing_kind: /v1, Kind: Service, new_kind: /v1, Kind: Service

# 原因：资源已存在

# 解决方法：
# 1. 检查是否已安装
helm list
helm status myapp

# 2. 如果是升级，使用upgrade --install
helm upgrade --install myapp ./mychart

# 3. 如果资源是手动创建的，先删除
kubectl delete service myapp

# 4. 使用不同的release名称
helm install myapp-v2 ./mychart
```

### 9.4.2 权限问题

```bash
# 错误示例
Error: INSTALLATION FAILED: services "myapp" is forbidden: User "system:serviceaccount:default:default" cannot create resource "services" in API group "" in the namespace "default"

# 解决方法：
# 1. 检查当前用户权限
kubectl auth can-i create services --namespace default

# 2. 检查kubeconfig
kubectl config current-context

# 3. 创建ServiceAccount和RBAC
kubectl create serviceaccount helm-deploy -n default
kubectl create rolebinding helm-deploy-admin --clusterrole=admin --serviceaccount=default:helm-deploy -n default

# 4. 使用有权限的kubeconfig
helm install myapp ./mychart --kubeconfig ~/.kube/config-admin
```

### 9.4.3 资源配额

```bash
# 错误示例
Error: INSTALLATION FAILED: pods "myapp-xxx" is forbidden: exceeded quota: compute-resources, requested: requests.cpu=500m, used: requests.cpu=3800m, limited: requests.cpu=4000m

# 解决方法：
# 1. 检查资源配额
kubectl describe resourcequota -n default

# 2. 调整资源请求
helm install myapp ./mychart --set resources.requests.cpu=100m

# 3. 请求增加配额
kubectl patch resourcequota compute-resources -n default --type=json -p='[{"op": "replace", "path": "/spec/hard/requests.cpu", "value": "8000m"}]'

# 4. 使用不同的命名空间
helm install myapp ./mychart -n myapp --create-namespace
```

---

## 9.5 依赖错误排除

### 9.5.1 依赖下载失败

```bash
# 错误示例
Error: can't get a valid version for repositories https://charts.bitnami.com/bitnami. Try version "12.x.x"

# 解决方法：
# 1. 更新仓库
helm repo update

# 2. 检查仓库连接
curl -I https://charts.bitnami.com/bitnami/index.yaml

# 3. 检查版本是否存在
helm search repo postgresql --versions

# 4. 使用精确版本
dependencies:
  - name: postgresql
    version: "12.12.0"

# 5. 清理并重建
rm -rf charts/ Chart.lock
helm dependency update
```

### 9.5.2 依赖循环

```bash
# 错误示例
Error: dependency cycle detected: chartA -> chartB -> chartA

# 解决方法：
# 1. 检查Chart.yaml中的依赖关系
# 2. 移除循环依赖
# 3. 考虑使用Library Chart共享模板
```

---

## 9.6 调试技巧

### 9.6.1 模板调试

```bash
# 1. 渲染模板但不安装
helm template myapp ./mychart

# 2. 只渲染特定模板
helm template myapp ./mychart -x templates/deployment.yaml

# 3. 调试模式
helm template myapp ./mychart --debug

# 4. 模拟安装
helm install myapp ./mychart --dry-run --debug

# 5. 查看渲染后的完整manifest
helm get manifest myapp

# 6. 查看渲染后的values
helm get values myapp --all

# 7. 查看所有信息
helm get all myapp
```

### 9.6.2 模板中调试

```yaml
# 使用fail输出调试信息
{{- fail (printf "Debug values: %v" .Values) }}

# 使用warn输出警告
{{- $_ := warn (printf "Warning: %v" .Values.someValue) }}

# 输出到注释
# Debug: {{ .Values | toJson }}

# 使用required确保必需值
{{- .Values.requiredValue | required "requiredValue is required!" -}}

# 使用条件输出调试信息
{{- if .Values.debug }}
# Debug info: {{ .Values | toJson }}
{{- end }}
```

### 9.6.3 Release调试

```bash
# 查看Release状态
helm status myapp

# 查看Release历史
helm history myapp

# 查看Release的manifest
helm get manifest myapp

# 查看Release的notes
helm get notes myapp

# 查看Release的values
helm get values myapp

# 查看Release的所有信息
helm get all myapp

# 查看Release存储的Secret
kubectl get secret -l owner=helm
kubectl get secret sh.helm.release.v1.myapp.v1 -o yaml
```

---

## 9.7 常见问题解决

### 9.7.1 Helm卡住

```bash
# 问题：helm install/upgrade命令卡住

# 可能原因：
# 1. --wait等待资源就绪
# 2. 资源创建失败但未超时
# 3. 网络问题

# 解决方法：
# 1. 设置超时时间
helm install myapp ./mychart --timeout 5m

# 2. 不使用--wait
helm install myapp ./mychart

# 3. 检查Pod状态
kubectl get pods -w

# 4. 检查事件
kubectl get events --sort-by='.lastTimestamp'

# 5. 检查资源状态
kubectl describe pod myapp-xxx
```

### 9.7.2 Release状态异常

```bash
# 问题：Release状态为failed或pending-install

# 查看状态
helm list --all
helm status myapp

# 解决方法：
# 1. 如果是pending状态，可能需要清理
helm uninstall myapp

# 2. 强制删除Release
kubectl delete secret sh.helm.release.v1.myapp.v1

# 3. 使用--force强制升级
helm upgrade myapp ./mychart --force

# 4. 回滚到上一个版本
helm rollback myapp
```

### 9.7.3 升级后问题

```bash
# 问题：升级后应用不工作

# 解决方法：
# 1. 查看升级历史
helm history myapp

# 2. 比较版本差异
helm diff revision myapp 1 2  # 需要helm-diff插件

# 3. 回滚到上一个版本
helm rollback myapp 1

# 4. 查看资源变化
helm get manifest myapp > current.yaml
helm get manifest myapp --revision 1 > previous.yaml
diff previous.yaml current.yaml

# 5. 检查Pod日志
kubectl logs -l app=myapp --previous
```

### 9.7.4 三路合并问题

```bash
# 问题：升级时资源被意外修改

# 原因：Helm 3的三路合并策略

# 解决方法：
# 1. 使用--force强制重新创建
helm upgrade myapp ./mychart --force

# 2. 使用--reset-values重置为默认值
helm upgrade myapp ./mychart --reset-values

# 3. 检查当前集群状态
kubectl get deployment myapp -o yaml

# 4. 手动修复资源
kubectl edit deployment myapp
```

---

## 9.8 日志和诊断

### 9.8.1 Helm日志

```bash
# 启用详细日志
helm install myapp ./mychart -v 6

# 日志级别：
# -v 0: 只显示错误
# -v 1: 显示警告
# -v 2: 显示信息
# -v 3: 显示扩展信息
# -v 4: 显示调试信息
# -v 5: 显示追踪信息
# -v 6: 显示详细追踪

# 查看Helm环境
helm env

# 查看Helm版本
helm version
```

### 9.8.2 Kubernetes事件

```bash
# 查看命名空间事件
kubectl get events -n default --sort-by='.lastTimestamp'

# 持续监控事件
kubectl get events -w

# 查看特定资源的事件
kubectl describe deployment myapp

# 查看Pod事件
kubectl describe pod myapp-xxx

# 查看所有事件
kubectl get events --all-namespaces
```

### 9.8.3 资源诊断

```bash
# 检查Pod状态
kubectl get pods -l app=myapp -o wide

# 查看Pod详情
kubectl describe pod myapp-xxx

# 查看容器日志
kubectl logs myapp-xxx
kubectl logs myapp-xxx -c container-name
kubectl logs myapp-xxx --previous

# 进入容器调试
kubectl exec -it myapp-xxx -- /bin/sh

# 检查资源配额
kubectl describe resourcequota

# 检查节点状态
kubectl describe node
```

---

## 9.9 预防措施

### 9.9.1 最佳实践

```
┌─────────────────────────────────────────────────────────────────┐
│  预防问题的最佳实践                                              │
└─────────────────────────────────────────────────────────────────┘

1. 使用--dry-run
   ├── 安装前预览
   ├── 检查模板语法
   └── 验证Values

2. 使用--wait
   ├── 确保资源就绪
   ├── 及时发现问题
   └── 设置合理超时

3. 使用--atomic
   ├── 失败自动回滚
   ├── 保持一致性
   └── 减少手动干预

4. 版本控制
   ├── 提交Chart到Git
   ├── 提交Values到Git
   └── 记录变更历史

5. 测试覆盖
   ├── 编写Chart测试
   ├── CI/CD集成
   └── 定期运行测试

6. 监控告警
   ├── 监控Release状态
   ├── 监控资源状态
   └── 设置告警规则
```

### 9.9.2 检查清单

```bash
# 安装前检查清单

# 1. 验证Chart
helm lint ./mychart --strict

# 2. 检查模板渲染
helm template myapp ./mychart --debug

# 3. 验证Values
helm template myapp ./mychart -f values.yaml --validate

# 4. 检查依赖
helm dependency list ./mychart

# 5. 检查权限
kubectl auth can-i create deployments --namespace default

# 6. 检查资源配额
kubectl describe resourcequota -n default

# 7. 模拟安装
helm install myapp ./mychart --dry-run

# 8. 查看将要创建的资源
helm template myapp ./mychart | kubectl apply --dry-run=client -f -
```

---

## 9.10 常见错误速查表

### 9.10.1 模板错误速查

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `unexpected EOF` | 模板语法错误，{{ }}不成对 | 检查模板语法，确保成对 |
| `map has no entry for key` | 变量未定义 | 使用 `default` 或 `required` |
| `wrong type for value` | 类型不匹配 | 使用类型转换函数 `int`, `toString` |
| `nil pointer evaluating` | 访问不存在的嵌套值 | 使用 `with` 或条件判断 |
| `error calling include` | 模板引用错误 | 检查模板名称和上下文 |
| `template: ... : executing` | 模板执行错误 | 使用 `--debug` 查看详情 |

### 9.10.2 安装/升级错误速查

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `resource already exists` | 资源已存在 | 使用 `upgrade --install` 或删除资源 |
| `forbidden: User cannot create` | 权限不足 | 检查RBAC配置 |
| `exceeded quota` | 资源配额不足 | 调整资源请求或增加配额 |
| `connection refused` | Kubernetes API不可达 | 检查kubeconfig和网络 |
| `context deadline exceeded` | 操作超时 | 增加超时时间 `--timeout` |
| `release myapp failed` | Release状态异常 | 查看详情 `helm status myapp` |

### 9.10.3 依赖错误速查

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `can't get a valid version` | 版本不存在 | 更新仓库 `helm repo update` |
| `dependency cycle detected` | 依赖循环 | 检查并移除循环依赖 |
| `no such host` | 仓库不可达 | 检查网络和仓库URL |
| `certificate signed by unknown` | TLS证书问题 | 使用 `--insecure-skip-tls-verify` |
| `unable to get credentials` | 认证失败 | 检查用户名密码或Token |

---

## 9.11 OCI注册表错误

### 9.11.1 登录失败

```bash
# 错误示例
Error: unable to retrieve credentials

# 解决方法：
# 1. 使用正确的凭据登录
helm registry login registry.example.com \
  --username myuser \
  --password mypassword

# 2. 使用Docker配置
# Helm会自动使用 ~/.docker/config.json
docker login registry.example.com

# 3. 使用环境变量
export HELM_REGISTRY_CONFIG=~/.docker/config.json

# 4. 检查登录状态
cat ~/.docker/config.json | grep registry.example.com
```

### 9.11.2 推送失败

```bash
# 错误示例
Error: failed to push: denied: requested access to the resource is denied

# 解决方法：
# 1. 检查权限
helm registry login registry.example.com

# 2. 检查仓库名称格式
# 正确格式: oci://registry.example.com/namespace/chart
helm push mychart-0.1.0.tgz oci://registry.example.com/myproject

# 3. 检查仓库是否存在
# 某些注册表需要预先创建仓库

# 4. 检查标签格式
helm push mychart-0.1.0.tgz oci://registry.example.com/charts
```

### 9.11.3 拉取失败

```bash
# 错误示例
Error: failed to authorize: failed to fetch anonymous token

# 解决方法：
# 1. 确保已登录
helm registry login registry.example.com

# 2. 检查Chart是否存在
helm show chart oci://registry.example.com/charts/mychart --version 0.1.0

# 3. 使用正确的版本号
helm pull oci://registry.example.com/charts/mychart --version 0.1.0

# 4. 检查网络连接
curl -I https://registry.example.com/v2/
```

---

## 9.12 网络和认证错误

### 9.12.1 仓库连接失败

```bash
# 错误示例
Error: looks like "https://charts.example.com" is not a valid chart repository or cannot be reached

# 解决方法：
# 1. 检查URL是否正确
curl -I https://charts.example.com/index.yaml

# 2. 检查网络连接
ping charts.example.com

# 3. 检查代理设置
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080

# 4. 跳过TLS验证（仅测试用）
helm repo add myrepo https://charts.example.com --insecure-skip-tls-verify

# 5. 使用自定义CA证书
helm repo add myrepo https://charts.example.com \
  --ca-file /path/to/ca.crt
```

### 9.12.2 TLS证书错误

```bash
# 错误示例
Error: x509: certificate signed by unknown authority

# 解决方法：
# 1. 添加CA证书到系统信任库
cp /path/to/ca.crt /usr/local/share/ca-certificates/
update-ca-certificates

# 2. 使用--ca-file指定证书
helm repo add myrepo https://charts.example.com \
  --ca-file /path/to/ca.crt

# 3. 临时跳过验证（不推荐生产使用）
helm repo add myrepo https://charts.example.com \
  --insecure-skip-tls-verify

# 4. 使用客户端证书
helm repo add myrepo https://charts.example.com \
  --ca-file /path/to/ca.crt \
  --cert-file /path/to/client.crt \
  --key-file /path/to/client.key
```

### 9.12.3 认证失败

```bash
# 错误示例
Error: unable to authenticate with registry

# 解决方法：
# 1. 检查用户名密码
helm repo add myrepo https://charts.example.com \
  --username myuser \
  --password mypassword

# 2. 使用Token认证
helm repo add myrepo https://charts.example.com \
  --username myuser \
  --password-file /path/to/token

# 3. 检查密码是否包含特殊字符
# 使用引号包裹
helm repo add myrepo https://charts.example.com \
  --username myuser \
  --password 'p@ssw0rd!'

# 4. 使用环境变量
export HELM_REPO_USERNAME=myuser
export HELM_REPO_PASSWORD=mypassword
helm repo add myrepo https://charts.example.com
```

---

## 9.13 实际案例分析

### 9.13.1 案例1: Pod启动失败

```bash
# 问题现象
helm install myapp ./mychart
# Pod状态一直是Pending或CrashLoopBackOff

# 排查步骤
# 1. 检查Pod状态
kubectl get pods -l app=myapp

# 2. 查看Pod事件
kubectl describe pod myapp-xxx

# 3. 查看容器日志
kubectl logs myapp-xxx

# 4. 查看前一个容器的日志
kubectl logs myapp-xxx --previous

# 常见原因及解决：
# - 镜像拉取失败：检查imagePullSecrets
# - 资源不足：调整resources或增加节点
# - 配置错误：检查ConfigMap和Secret
# - 存储挂载失败：检查PVC和StorageClass
# - 健康检查失败：调整livenessProbe/readinessProbe
```

### 9.13.2 案例2: 升级后服务不可用

```bash
# 问题现象
helm upgrade myapp ./mychart
# 服务无法访问

# 排查步骤
# 1. 检查Deployment状态
kubectl rollout status deployment/myapp

# 2. 检查Pod是否就绪
kubectl get pods -l app=myapp

# 3. 检查Service端点
kubectl get endpoints myapp

# 4. 检查Ingress配置
kubectl get ingress myapp -o yaml

# 5. 比较配置变化
helm diff revision myapp 1 2

# 常见原因及解决：
# - 配置变更导致应用启动失败：回滚或修复配置
# - Service selector不匹配：检查labels
# - Ingress配置错误：检查hosts和paths
# - 资源限制导致OOM：增加memory limits
```

### 9.13.3 案例3: 回滚失败

```bash
# 问题现象
helm rollback myapp 1
# Error: cannot rollback to revision 1

# 排查步骤
# 1. 检查历史版本
helm history myapp

# 2. 检查Release状态
helm status myapp

# 3. 检查Secret是否存在
kubectl get secret -l owner=helm,name=myapp

# 解决方法：
# 如果历史版本不存在，重新安装
helm uninstall myapp
helm install myapp ./mychart -f values-backup.yaml

# 如果Secret损坏，手动修复
kubectl get secret sh.helm.release.v1.myapp.v1 -o yaml > backup.yaml
# 编辑修复后重新apply
```

### 9.13.4 案例4: 依赖更新问题

```bash
# 问题现象
helm dependency update ./mychart
# Error: can't download chart

# 排查步骤
# 1. 检查仓库配置
helm repo list

# 2. 更新仓库索引
helm repo update

# 3. 检查版本是否存在
helm search repo postgresql --versions

# 4. 检查网络连接
curl -I https://charts.bitnami.com/bitnami/index.yaml

# 解决方法：
# 清理并重建
rm -rf charts/ Chart.lock
helm dependency update ./mychart

# 如果仍然失败，手动下载
helm pull bitnami/postgresql --version 12.12.0
tar -xzf postgresql-12.12.0.tgz -C charts/
```

---

## 9.14 错误诊断流程图

```
┌─────────────────────────────────────────────────────────────────┐
│  Helm错误诊断流程                                                │
└─────────────────────────────────────────────────────────────────┘

错误发生
    │
    ▼
┌─────────────────┐
│ helm --debug    │ 查看详细错误信息
└────────┬────────┘
         │
    ┌────┴────┐
    │ 错误类型 │
    └────┬────┘
         │
    ┌────┼────────────────────────────────────────┐
    │    │                                        │
    ▼    ▼                                        ▼
┌───────┐  ┌───────┐                      ┌───────┐
│模板错误│  │资源错误│                      │网络错误│
└───┬───┘  └───┬───┘                      └───┬───┘
    │          │                              │
    ▼          ▼                              ▼
┌───────┐  ┌───────┐                      ┌───────┐
│helm   │  │kubectl│                      │检查   │
│template│  │describe│                     │网络   │
│--debug│  │get events│                    │连接   │
└───────┘  └───────┘                      └───────┘
    │          │                              │
    └──────────┼──────────────────────────────┘
               │
               ▼
        ┌─────────────┐
        │ 查阅文档    │
        │ 搜索解决方案│
        │ 提交Issue   │
        └─────────────┘
```

---

## 9.15 获取帮助

### 9.15.1 官方资源

```bash
# Helm官方文档
# https://helm.sh/docs/

# Helm GitHub Issues
# https://github.com/helm/helm/issues

# Kubernetes官方文档
# https://kubernetes.io/docs/

# Stack Overflow
# 搜索标签: [helm] [kubernetes-helm]
```

### 9.15.2 社区资源

```bash
# Kubernetes Slack
# #helm 频道

# CNCF Slack
# #helm 频道

# Reddit
# r/kubernetes
# r/helm

# GitHub Discussions
# https://github.com/helm/helm/discussions
```

### 9.15.3 提问模板

```markdown
## 环境信息
- Helm版本: 
- Kubernetes版本: 
- 操作系统: 

## 问题描述
[描述遇到的问题]

## 复现步骤
1. 
2. 
3. 

## 错误信息
```
[粘贴完整的错误信息]
```

## 已尝试的解决方法
- [ ] 方法1
- [ ] 方法2

## 期望结果
[描述期望的结果]
```
