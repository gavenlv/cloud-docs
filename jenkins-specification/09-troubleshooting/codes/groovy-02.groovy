// 问题: 构建超时
// 错误信息: Execution expired

// 解决方案:
# 1. 增加超时时间
pipeline {
    options {
        timeout(time: 2, unit: 'HOURS')
    }
}

# 2. 步骤级别超时
steps {
    timeout(time: 30, unit: 'MINUTES') {
        sh './long-task.sh'
    }
}

# 3. 检查是否有死锁