# ---------------------------------
# Amazon ECR Repository
# ---------------------------------

resource "aws_ecr_repository" "hydroserver" {
  name         = "hydroserver-${var.instance}"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}
