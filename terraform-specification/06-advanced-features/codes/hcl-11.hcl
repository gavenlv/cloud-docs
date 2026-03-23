# 使用terraform-compliance进行测试

# 测试文件：test/policy.feature
Feature: VPC Network Policy

  Scenario: VPC should have auto_create_subnetworks disabled
    Given I have vpc resource defined
    Then it must contain auto_create_subnetworks
    And its value must be false

  Scenario: VPC should have routing_mode set to REGIONAL
    Given I have vpc resource defined
    Then it must contain routing_mode
    And its value must be REGIONAL

  Scenario: VPC should have labels
    Given I have vpc resource defined
    Then it must contain labels
    And labels must contain environment
    And labels must contain managed_by