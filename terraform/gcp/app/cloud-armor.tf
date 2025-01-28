# -------------------------------------------------- #
# Cloud Armor Security Policy                        #
# -------------------------------------------------- #

resource "google_compute_security_policy" "hydroserver_security_policy" {
  name        = "hydroserver-security-policy-${var.instance}"
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
      priority    = 1000
      description = "Block SQL Injection Attempts"
      expression  = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 2})"
    },
    {
      action      = "deny(403)"
      priority    = 1001
      description = "Prevent XSS Attacks"
      expression  = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 2})"
    },
    {
      action      = "deny(403)"
      priority    = 1002
      description = "Block Local File Inclusion"
      expression  = "evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': 2})"
    },
    {
      action      = "deny(403)"
      priority    = 1003
      description = "Block Remote File Inclusion"
      expression  = "evaluatePreconfiguredWaf('rfi-v33-stable', {'sensitivity': 2})"
    },
    {
      action      = "deny(403)"
      priority    = 1004
      description = "Perform Scanner Detection"
      expression  = "evaluatePreconfiguredWaf('scannerdetection-v33-stable', {'sensitivity': 2})"
    },
    {
      action      = "deny(403)"
      priority    = 1005
      description = "Prevent Protocol Attacks"
      expression  = "evaluatePreconfiguredWaf('protocolattack-v33-stable', {'sensitivity': 2})"
    },
    {
      action      = "deny(403)"
      priority    = 1006
      description = "Prevent Session Fixation Attacks"
      expression  = "evaluatePreconfiguredWaf('sessionfixation-v33-stable', {'sensitivity': 2})"
    },
    {
      action      = "deny(403)"
      priority    = 1007
      description = "Log4j Vulnerability"
      expression  = "evaluatePreconfiguredWaf('cve-canary', {'sensitivity': 2})"
    },
    {
      action      = "deny(403)"
      priority    = 1008
      description = "Block JSON SQL Injection Attempts"
      expression  = "evaluatePreconfiguredWaf('json-sqli-canary', {'sensitivity': 2})"
    },
  ]
}
