# Jenkins配置文件 (init.groovy.d/)

# 示例: 设置执行器数量
import jenkins.model.Jenkins

Jenkins.instance.setNumExecutors(2)
Jenkins.instance.setLabel(null)

// 设置系统消息
Jenkins.instance.setSystemMessage("Welcome to Jenkins CI/CD Platform")

// 禁用旧版API token
Jenkins.instance.getActiveRealm().setUseSecurity(true)

// 设置SMTP服务器
import hudson.tasks.Mailer
Mailer.descriptor().setSmtpHost("smtp.example.com")