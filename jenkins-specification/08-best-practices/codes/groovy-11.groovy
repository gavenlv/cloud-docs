// 使用更多Agent分散负载
// Manage Jenkins → Manage Nodes → Configure
// # of executors: 4

// 为不同任务配置专门Agent
pipeline {
    agent {
        label 'java'  // Java构建使用专用节点
    }
}

// Kubernetes动态Agent
pipeline {
    agent {
        kubernetes {
            label 'dynamic'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
  - name: builder
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
'''
        }
    }
}