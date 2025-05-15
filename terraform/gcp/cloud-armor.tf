# ---------------------------------
# Cloud Armor Security Policy
# ---------------------------------

resource "google_compute_security_policy" "security_policy" {
  name        = "hydroserver-${var.instance}-security-policy"
  description = "WAF policy for HydroServer Load Balancer"

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
      rule_visibility = "STANDARD"
    }
  }

  rule {
    description = "Default Rule"
    action      = "allow"
    priority    = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  dynamic "rule" {
    for_each = var.cloud_armor_rules
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      match {
        expr {
          expression = rule.value.expression
        }
      }
    }
  }
}

variable "cloud_armor_rules" {
  type = list(object({
    action      = string
    priority    = number
    description = string
    expression  = string
  }))
  default = [
    {
      action      = "deny(403)"
      priority    = 1001
      description = "Prevent SQL Injection"
      expression  = "evaluatePreconfiguredWaf('owasp-crs-v030001', ['crs-30-sqli'], {'sensitivity': 1})"
    },
    {
      action      = "deny(403)"
      priority    = 1002
      description = "Prevent Cross-Site Scripting (XSS)"
      expression  = "evaluatePreconfiguredWaf('owasp-crs-v030001', ['crs-30-xss'], {'sensitivity': 1})"
    },
    {
      action      = "deny(403)"
      priority    = 1003
      description = "Prevent Local File Inclusion (LFI)"
      expression  = "evaluatePreconfiguredWaf('owasp-crs-v030001', ['crs-30-lfi'], {'sensitivity': 1})"
    },
    {
      action      = "deny(403)"
      priority    = 1004
      description = "Prevent Protocol Violations"
      expression  = "evaluatePreconfiguredWaf('owasp-crs-v030001', ['crs-30-protocol-violations'], {'sensitivity': 1})"
    },
    {
      action      = "deny(429)"
      priority    = 2000
      description = "Rate limit to 10 requests per second per IP"
      expression  = "rate_based_rule(10)"
    }
  ]
}
