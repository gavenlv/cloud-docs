// 用户API Token配置
// 用户 → Configure → API Token

// 使用API Token访问
curl -u "username:api_token" http://jenkins:8080/api/json

// 或
curl -H "Authorization: $(echo -n username:token | base64)" \
     http://jenkins:8080/api/json