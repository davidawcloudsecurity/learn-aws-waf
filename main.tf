variable "region" {
  type        = string
  description = "The AWS region where resources are to be created."
  default     = "us-west-2"
}

variable "waf_name" {
  type        = string
  description = "The name of the WAF Web ACL."
  default     = "example-wafv2-acl"
}

variable "alb_name" {
  type        = string
  description = "The name of the existing Application Load Balancer."
}

provider "aws" {
  region = var.region
}

# Create a CloudWatch Log Group for WAF logs
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/wafv2/${var.waf_name}"
  retention_in_days = 30  # Adjust retention as needed
}

# Data source to fetch existing ALB
data "aws_lb" "existing_alb" {
  name = var.alb_name
}

resource "aws_wafv2_web_acl" "example" {
  name        = var.waf_name
  description = "Example WAFv2 ACL for existing ALB with CloudWatch Metrics"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true  # Changed to true for full logging
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "example-web-acl-metric"
    sampled_requests_enabled   = true  # Changed to true for full logging
  }
}

# Associate the Web ACL with the existing ALB
resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = data.aws_lb.existing_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.example.arn
}

# Enable logging for the Web ACL to CloudWatch Logs
resource "aws_wafv2_web_acl_logging_configuration" "example" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.example.arn

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior = "KEEP"
      condition = "REQUEST"
      requirement = "NOT_EXISTS"
    }

    filter {
      behavior = "KEEP"
      condition = "RESPONSE"
      requirement = "NOT_EXISTS"
    }
  }
}
