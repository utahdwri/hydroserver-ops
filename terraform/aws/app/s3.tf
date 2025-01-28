# -------------------------------------------------- #
# HydroServer API Storage Bucket                     #
# -------------------------------------------------- #

resource "aws_s3_bucket" "hydroserver_storage_bucket" {
  bucket = "hydroserver-storage-${var.instance}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "hydroserver_storage_bucket" {
  bucket = aws_s3_bucket.hydroserver_storage_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "hydroserver_storage_bucket" {
  bucket = aws_s3_bucket.hydroserver_storage_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.hydroserver_storage_bucket]
}

resource "aws_s3_object" "media_folder" {
  bucket = aws_s3_bucket.hydroserver_storage_bucket.id
  key    = "photos/"
}

resource "aws_s3_object" "static_folder" {
  bucket = aws_s3_bucket.hydroserver_storage_bucket.id
  key    = "static/"
}

# -------------------------------------------------- #
# HydroServer Data Management App Bucket             #
# -------------------------------------------------- #

resource "aws_s3_bucket" "hydroserver_data_mgmt_app_bucket" {
  bucket = "hydroserver-data-mgmt-app-${var.instance}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "hydroserver_data_mgmt_app_bucket" {
  bucket = aws_s3_bucket.hydroserver_data_mgmt_app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "hydroserver_data_mgmt_app_bucket" {
  bucket = aws_s3_bucket.hydroserver_data_mgmt_app_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.hydroserver_data_mgmt_app_bucket]
}

# ------------------------------------------------ #
# HydroServer S3 Bucket Policies                   #
# ------------------------------------------------ #

# resource "aws_s3_bucket_policy" "hydroserver_data_mgmt_app_bucket" {
#   bucket = aws_s3_bucket.hydroserver_data_mgmt_app_bucket.id
#   policy = jsonencode({
#     Version = "2008-10-17"
#     Id      = "PolicyForCloudFrontPrivateContent"
#     Statement = [
#       {
#         Sid    = "AllowCloudFrontServicePrincipal"
#         Effect = "Allow"
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }
#         Action   = "s3:GetObject"
#         Resource = "${aws_s3_bucket.hydroserver_data_mgmt_app_bucket.arn}/*"
#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = aws_cloudfront_distribution.hydroserver_distribution.arn
#           }
#         }
#       }
#     ]
#   })

#   depends_on = [
#     aws_cloudfront_distribution.hydroserver_distribution,
#     aws_s3_bucket_public_access_block.hydroserver_data_mgmt_app_bucket
#   ]
# }

# resource "aws_s3_bucket_policy" "hydroserver_storage_bucket" {
#   bucket = aws_s3_bucket.hydroserver_storage_bucket.id
#   policy = jsonencode({
#     Version = "2008-10-17"
#     Id      = "PolicyForCloudFrontPrivateContent"
#     Statement = [
#       {
#         Sid    = "AllowCloudFrontServicePrincipal"
#         Effect = "Allow"
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }
#         Action   = "s3:GetObject"
#         Resource = "${aws_s3_bucket.hydroserver_storage_bucket.arn}/*"
#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = aws_cloudfront_distribution.hydroserver_distribution.arn
#           }
#         }
#       }
#     ]
#   })

#   depends_on = [
#     aws_cloudfront_distribution.hydroserver_distribution,
#     aws_s3_bucket_public_access_block.hydroserver_api_storage_bucket
#   ]
# }

# -------------------------------------------------- #
# Placeholder index.html File                        #
# -------------------------------------------------- #

resource "aws_s3_object" "hydroserver_data_mgmt_app_default_index" {
  bucket = aws_s3_bucket.hydroserver_data_mgmt_app_bucket.id
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
