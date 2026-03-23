# 插件管理

## 本章导学

**学完本章后，你将能够：**

- 掌握Jenkins插件安装和配置
- 理解插件依赖管理
- 掌握插件更新和回滚

**学习方法：**

```
插件市场 → 安装配置 → 依赖管理 → 更新回滚
```

---

# 1. 插件基础

## 1.1 插件架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins插件架构                               │
└─────────────────────────────────────────────────────────────────┘

# Jenkins核心功能有限，主要通过插件扩展
# 1800+ 官方插件

# 插件类型:
┌─────────────────────────────────────────────────────────────────┐
│ 类型              │ 说明                                        │
├───────────────────┼────────────────────────────────────────────┤
│ Source Code Management│ Git, SVN, CVS等                          │
│ Build Trigger     │ 定时构建, Webhook等                          │
│ Build Steps       │ 各种构建步骤                                │
│ Post-build Actions│ 构建后操作                                  │
│ Authentication    │ 认证相关                                    │
│ Authorization     │ 授权相关                                    │
│ UI/Visualization │ 界面展示                                    │
└─────────────────────────────────────────────────────────────────┘

# 插件位置: ~/.jenkins/plugins/
```

## 1.2 插件管理器

```
┌─────────────────────────────────────────────────────────────────┐
│                    插件管理界面                                   │
└─────────────────────────────────────────────────────────────────┘

# 访问路径: Manage Jenkins → Manage Plugins

# 标签页:
# - Updates: 可更新的插件
# - Available: 可安装的插件
# - Installed: 已安装的插件
# - Advanced: 高级配置

# 高级配置:
# - 插件更新站点
# - 手动上传插件
# - 代理设置
```

---

# 2. 插件安装

## 2.1 Web界面安装

```bash
# 方式1: 直接安装
# Manage Jenkins → Manage Plugins → Available
# 搜索并选择插件
# 点击 "Install without restart" 或 "Download now and install after restart"

# 方式2: 高级安装
# Manage Jenkins → Manage Plugins → Advanced
# Upload plugin: 上传.hpi文件
```

## 2.2 命令行安装

```bash
# 方式1: 使用jenkins-cli.jar
java -jar jenkins-cli.jar \
     -s http://jenkins:8080 \
     -auth user:token \
     install-plugin git pipeline-stage-view blueocean

# 方式2: 复制插件文件
# 下载.hpi文件
cp git.hpi ~/.jenkins/plugins/
systemctl restart jenkins

# 方式3: Docker方式
# 在Dockerfile中
RUN jenkins-plugin-cli --plugins git pipeline-stage-view blueocean
```

## 2.3 Dockerfile安装

```dockerfile
FROM jenkins/jenkins:lts

# 使用jenkins-plugin-cli安装插件
RUN jenkins-plugin-cli \
    --plugins \
    git \
    docker-workflow \
    pipeline-stage-view \
    blueocean \
    slack \
    email-ext

# 或使用plugins.txt
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
```

```text
# plugins.txt格式
git:4.10.0
docker-workflow:1.26
pipeline-stage-view:2.24
blueocean:1.24.8
slack:2.46
email-ext:2.88
```

---

# 3. 常用插件

## 3.1 Pipeline相关

```groovy
# 常用Pipeline插件

# 1. Pipeline: 核心Pipeline支持
# 内置，无需安装

# 2. Workflow Aggregator: Pipeline聚合
# 内置，无需安装

# 3. Pipeline: Stage View
# 可视化Pipeline执行

# 4. Blue Ocean
# 新一代Pipeline UI
# 安装: blueocean

# 5. Docker Pipeline
# 在Pipeline中使用Docker
# 安装: docker-workflow
pipeline {
    agent {
        docker { image 'maven:3.8-openjdk-11' }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}

# 6. Kubernetes Pipeline
# Kubernetes集成
# 安装: kubernetes
```

## 3.2 源码管理

```groovy
# 常用源码管理插件

# 1. Git
# 最流行的源码管理
# 安装: git
# 配置:
git branch: 'main',
    url: 'https://github.com/example/app.git',
    credentialsId: 'git-credentials'

# 2. GitHub
# GitHub集成
# 安装: github
# 配置Webhook自动触发构建

# 3. GitLab
# GitLab集成
# 安装: gitlab

# 4. Subversion
# 安装: subversion
```

## 3.3 通知相关

```groovy
# 常用通知插件

# 1. Slack
# 安装: slack
steps {
    slackSend channel: '#ci-cd',
              color: 'good',
              message: "构建成功: ${env.JOB_NAME}"
}

# 2. Email Extension
# 安装: email-ext
steps {
    emailext(
        subject: "构建 ${currentBuild.result}: ${env.JOB_NAME}",
        body: """
            构建结果: ${currentBuild.result}
            构建编号: ${env.BUILD_NUMBER}
            构建URL: ${env.BUILD_URL}
        """,
        to: 'team@example.com'
    )
}

# 3. Discord
# 安装: discord
steps {
    discordSend webhookURL: 'YOUR_WEBHOOK_URL',
                 title: 'Build Complete',
                 description: 'Build finished'
}
```

## 3.4 报告相关

```groovy
# 常用报告插件

# 1. JUnit
# 测试报告
# 内置
steps {
    junit '**/target/surefire-reports/*.xml'
}

# 2. Cobertura
# 代码覆盖率
# 安装: cobertura
steps {
    cobertura coberturaReportFile: '**/coverage.xml'
}

# 3. JaCoCo
# 代码覆盖率
# 安装: jacoco
steps {
    jacoco execPattern: '**/target/*.exec'
}

# 4. SonarQube
# 代码质量
# 安装: sonar
steps {
    withSonarQubeEnv('sonar') {
        sh 'mvn sonar:sonar'
    }
}
```

---

# 4. 插件依赖

## 4.1 依赖机制

```
┌─────────────────────────────────────────────────────────────────┐
│                    插件依赖机制                                   │
└─────────────────────────────────────────────────────────────────┘

# Jenkins插件使用插件依赖管理器 (Plugin Dependency Manager)

# 依赖格式 (.jpi文件中的 MANIFEST.MF):
# Plugin-Dependencies: git:4.10.0,Pipeline:2.24

# 依赖解决:
# - 自动安装依赖
# - 按正确顺序加载
# - 依赖冲突检测

# 常见依赖问题:
# - 版本不兼容
# - 循环依赖
# - 缺失依赖
```

## 4.2 依赖查看

```bash
# 查看插件依赖
# Manage Jenkins → Manage Plugins → Installed
# 点击插件查看详情

# 使用jenkins-cli
java -jar jenkins-cli.jar \
     -s http://jenkins:8080 \
     -auth user:token \
     list-plugins

# 查看特定插件信息
java -jar jenkins-cli.jar \
     -s http://jenkins:8080 \
     -auth user:token \
     get-plugin git
```

## 4.3 依赖问题处理

```
┌─────────────────────────────────────────────────────────────────┐
│                    依赖问题处理                                   │
└─────────────────────────────────────────────────────────────────┘

# 问题1: 缺少依赖
# 解决: 安装缺失的依赖插件

# 问题2: 版本冲突
# 解决: 升级/降级插件版本

# 问题3: 循环依赖
# 解决: 升级到支持解耦的版本

# 故障排除:
# 查看: Manage Jenkins → System Log → All Log Entries
```

---

# 5. 插件更新和回滚

## 5.1 插件更新

```bash
# 方式1: Web界面更新
# Manage Jenkins → Manage Plugins → Updates
# 选择插件，点击 "Download now and install after restart"

# 方式2: 手动上传
# 下载新版.hpi
# Manage Jenkins → Manage Plugins → Advanced → Upload plugin

# 方式3: 命令行
java -jar jenkins-cli.jar \
     -s http://jenkins:8080 \
     -auth user:token \
     install-plugin git -deploy
```

## 5.2 插件回滚

```bash
# 回滚步骤:
# 1. 停止Jenkins
systemctl stop jenkins

# 2. 备份当前插件
cp -r ~/.jenkins/plugins ~/.jenkins/plugins.backup

# 3. 删除问题插件
rm -rf ~/.jenkins/plugins/git.hpi
rm -rf ~/.jenkins/plugins/git/

# 4. 安装旧版本
# 下载旧版本.hpi
cp old-version.hpi ~/.jenkins/plugins/git.hpi

# 5. 重启Jenkins
systemctl start jenkins

# 或者使用插件:
# Install: Prev/Next Plugin Version Manager
```

## 5.3 插件版本管理

```bash
# 版本锁定
# 在Docker中
FROM jenkins/jenkins:lts

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# 定期更新脚本
#!/bin/bash
# update-plugins.sh

JENKINS_URL="http://jenkins:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="your-token"

PLUGINS=("git" "pipeline-stage-view" "blueocean")

for plugin in "${PLUGINS[@]}"; do
    echo "更新插件: $plugin"
    java -jar jenkins-cli.jar \
        -s $JENKINS_URL \
        -auth $JENKINS_USER:$JENKINS_TOKEN \
        install-plugin $plugin
done

echo "重启Jenkins..."
java -jar jenkins-cli.jar \
    -s $JENKINS_URL \
    -auth $JENKINS_USER:$JENKINS_TOKEN \
    safe-restart
```

---

# 6. 插件开发基础

## 6.1 开发环境

```xml
<!-- pom.xml -->
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>my-jenkins-plugin</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>hpi</packaging>

    <parent>
        <groupId>org.jenkins-ci.plugins</groupId>
        <artifactId>plugin</artifactId>
        <version>4.40</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.jenkins-ci.plugins</groupId>
            <artifactId>git</artifactId>
            <version>4.10.0</version>
        </dependency>
    </dependencies>
</project>
```

## 6.2 简单插件示例

```java
// src/main/java/com/example/HelloWorldBuilder.java
package com.example;

import hudson.Launcher;
import hudson.EnvVars;
import hudson.model.TaskListener;
import hudson.tasks.Builder;
import org.jenkinsci.Symbol;

public class HelloWorldBuilder extends Builder {

    private final String name;

    @DataBoundConstructor
    public HelloWorldBuilder(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    @Override
    public void perform(
        Run<?, ?> run,
        FilePath workspace,
        Launcher launcher,
        TaskListener listener
    ) throws InterruptedException, IOException {
        listener.getLogger().println("Hello, " + name + "!");
    }

    @Symbol("helloWorld")
    @Extension
    public static class DescriptorImpl extends BuildStepDescriptor<Builder> {
        @Override
        public boolean isApplicable(Class<? extends AbstractProject> aClass) {
            return true;
        }
    }
}
```

```java
// src/main/resources/index.jelly
<?jelly escape-by-default='true'?>
<div>
    Hello, World! This is my first Jenkins plugin.
</div>
```

---

## 本章小结

- **Jenkins插件**是扩展Jenkins功能的核心机制
- **安装方式**: Web界面、命令行、Dockerfile
- **常用插件**: Git、Pipeline相关、Docker、通知、报告
- **依赖管理**: 自动解决依赖，注意版本兼容性
- **更新回滚**: 使用备份和版本管理器

**常用插件列表:**

```bash
# 核心插件
git, subversion
pipeline, workflow-aggregator
docker-workflow
blueocean

# 集成插件
github, gitlab
slack, email-ext
junit, jacoco, cobertura
sonar

# 安全插件
role-strategy
matrix-auth
```