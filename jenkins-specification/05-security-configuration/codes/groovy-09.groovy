// 获取crumb
CRUMB=$(curl -s "http://user:token@jenkins:8080/crumbIssuer/api/json" | jq -r .crumbRequestField":"crumb)

// 创建构建
curl -X POST \
     -H "${CRUMB}" \
     -u "user:token" \
     http://jenkins:8080/job/myjob/build

// 获取构建状态
curl -u "user:token" \
     "http://jenkins:8080/job/myjob/lastBuild/api/json"

// 获取控制台输出
curl -u "user:token" \
     "http://jenkins:8080/job/myjob/lastBuild/consoleText"

// 触发参数化构建
curl -X POST \
     -H "${CRUMB}" \
     -u "user:token" \
     -d "param1=value1&param2=value2" \
     http://jenkins:8080/job/myjob/buildWithParameters