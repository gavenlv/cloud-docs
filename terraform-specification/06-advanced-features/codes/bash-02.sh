# 使用terratest进行集成测试

# test/vpc_test.go
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestVPC(t *testing.T) {
  t.Parallel()

  terraformOptions := &terraform.Options{
    TerraformDir: "../examples/vpc",

    Vars: map[string]interface{}{
      "project_id": "test-project-id",
      "network_name": "test-network",
    },
  }

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

  networkID := terraform.Output(t, terraformOptions, "network_id")
  assert.NotEmpty(t, networkID)

  networkName := terraform.Output(t, terraformOptions, "network_name")
  assert.Equal(t, "test-network", networkName)
}