# ---------------------------------
# Amazon ECR Repository
# ---------------------------------

resource "aws_ecr_repository" "api_repository" {
  name         = "hydroserver-api-${var.instance}"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}
