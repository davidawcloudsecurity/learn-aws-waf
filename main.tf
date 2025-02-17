provider "aws" {
  region = var.region  # Change to your desired region
}

variable "region" {
  type        = string
  description = "The AWS region where resources are to be created."
  default     = "us-west-2"  # Default region if not specified
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
# Data source to fetch existing ALB
data "aws_lb" "existing_alb" {
  name = var.alb_name
}

resource "aws_wafv2_web_acl" "example" {
  name        = var.waf_name
  description = "Example WAFv2 ACL for existing ALB with CloudWatch Metrics"
  scope       = "REGIONAL"  # Use "REGIONAL" for resources like ALB, API Gateway (not CloudFront)

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
      # Enable metrics collection for this rule to CloudWatch
      cloudwatch_metrics_enabled = true  
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      # Disable detailed logging of individual requests
      sampled_requests_enabled   = false  
    }
  }

  visibility_config {
    # Enable metrics collection for the entire Web ACL
    cloudwatch_metrics_enabled = true  
    metric_name                = "example-web-acl-metric"
    # Disable detailed logging of individual requests for the entire Web ACL
    sampled_requests_enabled   = false  
  }
}

# Associate the Web ACL with the existing ALB
resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = data.aws_lb.existing_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.example.arn
}
