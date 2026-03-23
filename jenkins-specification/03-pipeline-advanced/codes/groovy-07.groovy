// src/com/example/Utils.groovy
package com.example

class Utils implements Serializable {
    def steps

    Utils(steps) {
        this.steps = steps
    }

    def runMaven(String goals) {
        steps.sh "mvn ${goals}"
    }

    def notify(String message) {
        steps.echo "通知: ${message}"
    }

    def retry(int maxRetries, Closure action) {
        for (int i = 0; i < maxRetries; i++) {
            try {
                return action()
            } catch (Exception e) {
                if (i == maxRetries - 1) {
                    throw e
                }
                steps.echo "重试 ${i + 1}/${maxRetries}"
                steps.sleep 5
            }
        }
    }
}