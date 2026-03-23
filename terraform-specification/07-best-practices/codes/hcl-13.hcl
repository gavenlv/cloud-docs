# 监控成本

resource "google_billing_budget" "monthly_budget" {
  billing_account = "billingAccounts/123456-7890AB-ABCDEF"
  display_name   = "Monthly Budget"

  budget_filter {
    projects = ["projects/my-project-id"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "1000"
    }
  }

  threshold_rules {
    threshold_percent = 90.0
    spend_basis      = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 100.0
    spend_basis      = "CURRENT_SPEND"
  }

  all_updates_rule {
    pubsub_topic = google_pubsub_topic.budget_alerts.id
  }
}

resource "google_pubsub_topic" "budget_alerts" {
  name = "budget-alerts"
}