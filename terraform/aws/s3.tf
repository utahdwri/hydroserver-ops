# ---------------------------------
# AWS S3 Static Bucket
# ---------------------------------

resource "aws_s3_bucket" "static_bucket" {
  bucket = "hydroserver-static-${var.instance}-${data.aws_caller_identity.current.account_id}"

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_s3_bucket_public_access_block" "static_bucket" {
  bucket = aws_s3_bucket.static_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "static_bucket" {
  bucket = aws_s3_bucket.static_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.static_bucket]
}

resource "aws_s3_object" "static_folder" {
  bucket = aws_s3_bucket.static_bucket.id
  key    = "static/"
}

resource "aws_s3_bucket_policy" "static_bucket" {
  bucket = aws_s3_bucket.static_bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.url_map.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_cloudfront_distribution.url_map,
    aws_s3_bucket_public_access_block.static_bucket
  ]
}


# ---------------------------------
# AWS S3 Media Bucket
# ---------------------------------

resource "aws_s3_bucket" "media_bucket" {
  bucket = "hydroserver-media-${var.instance}-${data.aws_caller_identity.current.account_id}"

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_s3_bucket_public_access_block" "media_bucket" {
  bucket = aws_s3_bucket.media_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "media_bucket" {
  bucket = aws_s3_bucket.media_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.media_bucket]
}

resource "aws_s3_object" "media_folder" {
  bucket = aws_s3_bucket.media_bucket.id
  key    = "media/"
}

resource "aws_s3_bucket_policy" "media_bucket" {
  bucket = aws_s3_bucket.media_bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.media_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.url_map.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_cloudfront_distribution.url_map,
    aws_s3_bucket_public_access_block.media_bucket
  ]
}


# ---------------------------------
# AWS S3 Data Management App Bucket
# ---------------------------------

resource "aws_s3_bucket" "data_mgmt_app_bucket" {
  bucket = "hydroserver-data-mgmt-app-${var.instance}-${data.aws_caller_identity.current.account_id}"

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_s3_bucket_public_access_block" "data_mgmt_app_bucket" {
  bucket = aws_s3_bucket.data_mgmt_app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "data_mgmt_app_bucket" {
  bucket = aws_s3_bucket.data_mgmt_app_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.data_mgmt_app_bucket]
}

resource "aws_s3_bucket_policy" "data_mgmt_app_bucket" {
  bucket = aws_s3_bucket.data_mgmt_app_bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.data_mgmt_app_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.url_map.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_cloudfront_distribution.url_map,
    aws_s3_bucket_public_access_block.data_mgmt_app_bucket
  ]
}

resource "aws_s3_object" "default_index_html" {
  bucket = aws_s3_bucket.data_mgmt_app_bucket.id
  key    = "index.html"

  content = <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Placeholder Page</title>
</head>
<body>
    <h1>Welcome to HydroServer</h1>
    <p>This is a placeholder page served from AWS S3.</p>
</body>
</html>
EOF

  cache_control = "no-cache"

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}
