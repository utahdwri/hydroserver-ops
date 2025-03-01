# ---------------------------------
# CloudFront Distribution
# ---------------------------------

resource "aws_cloudfront_distribution" "url_map" {
  origin {
    origin_id                = "data-mgmt-app"
    domain_name              = aws_s3_bucket.data_mgmt_app_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  origin {
    origin_id                = "static"
    domain_name              = aws_s3_bucket.static_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  origin {
    origin_id                = "media"
    domain_name              = aws_s3_bucket.media_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  origin {
    origin_id   = "api-service"
    domain_name = aws_apprunner_service.api.service_url

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port = "80"
      https_port = "443"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id = "data-mgmt-app"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn   = aws_cloudfront_function.frontend_routing.arn
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/api/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "api-service"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.cdn_managed_caching_disabled_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cdn_managed_all_viewer_origin_request_policy.id

    function_association {
      event_type     = "viewer-request"
      function_arn   = aws_cloudfront_function.x_forward_host.arn
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/admin/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "api-service"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.cdn_managed_caching_disabled_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cdn_managed_all_viewer_origin_request_policy.id

    function_association {
      event_type     = "viewer-request"
      function_arn   = aws_cloudfront_function.x_forward_host.arn
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/accounts/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "api-service"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.cdn_managed_caching_disabled_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cdn_managed_all_viewer_origin_request_policy.id

    function_association {
      event_type     = "viewer-request"
      function_arn   = aws_cloudfront_function.x_forward_host.arn
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/media/*"
    target_origin_id       = "media"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]

    trusted_key_groups = [aws_cloudfront_key_group.cloudfront_key_group.id]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "static"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = [local.domain]

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  enabled             = true
  is_ipv6_enabled     = true
  web_acl_id          = aws_wafv2_web_acl.core_rules.arn

  lifecycle {
    ignore_changes = [
      viewer_certificate,
      aliases
    ]
  }

  tags = {
    (var.tag_key) = local.tag_value
  }
}


# ---------------------------------
# RSA Key Pair
# ---------------------------------

resource "tls_private_key" "cloudfront_signing_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_cloudfront_public_key" "cloudfront_pub_key" {
  name        = "hydroserver-${var.instance}-public-key"
  encoded_key = tls_private_key.cloudfront_signing_key.public_key_pem
}

resource "aws_cloudfront_key_group" "cloudfront_key_group" {
  name  = "hydroserver-${var.instance}-key-group"
  items = [aws_cloudfront_public_key.cloudfront_pub_key.id]
}

resource "aws_ssm_parameter" "signing_key_id" {
  name        = "/hydroserver-${var.instance}-api/signing-key-id"
  type        = "String"
  value       = aws_cloudfront_public_key.cloudfront_pub_key.id

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_ssm_parameter" "signing_key" {
  name        = "/hydroserver-${var.instance}-api/signing-key"
  type        = "SecureString"
  value       = tls_private_key.cloudfront_signing_key.private_key_pem

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# CloudFront Access Controls
# ---------------------------------

data "aws_cloudfront_cache_policy" "cdn_managed_caching_disabled_cache_policy" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "cdn_managed_all_viewer_origin_request_policy" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_function" "frontend_routing" {
  name    = "frontend-routing-${var.instance}"
  runtime = "cloudfront-js-1.0"
  comment = "Preserve Vue client-side routing."
  code    = file("${path.module}/frontend-routing.js")
  publish = true
}

resource "aws_cloudfront_function" "x_forward_host" {
  name    = "x-forwarded-host-${var.instance}"
  runtime = "cloudfront-js-1.0"
  comment = "Include x-forwarded-host in the header."
  code    = file("${path.module}/x-forwarded-host.js")
  publish = true
}

resource "aws_cloudfront_origin_access_identity" "oai" {}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "hydroserver-oac-${var.instance}"
  description                       = ""
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_wafv2_web_acl" "core_rules" {
  name        = "CoreRulesWebACL-${var.instance}"
  scope       = "CLOUDFRONT"
  description = "WAF web ACL with Core Rules"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAF_Common_Protections"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SizeRestrictions_BODY"
        }
        rule_action_override {
          action_to_use {
            allow {}
          }
          name = "NoUserAgent_HEADER"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    (var.tag_key) = local.tag_value
  }
}
