# ------------------------------------------------ #
# HydroServer EC2 IAM Role                         #
# ------------------------------------------------ #

resource "aws_iam_role" "elasticbeanstalk_role" {
  name               = "hydroserver-ec2-role-${var.instance}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/HydroServerIAMPermissionBoundary"
}

resource "aws_iam_instance_profile" "elasticbeanstalk_instance_profile" {
  name = "hydroserver-ec2-role-${var.instance}"
  role = aws_iam_role.elasticbeanstalk_role.name
}

# ------------------------------------------------ #
# HydroServer EC2 IAM Role Attach Policies         #
# ------------------------------------------------ #

resource "aws_iam_role_policy_attachment" "elasticbeanstalk_multicontainer_docker_attachment" {
  role       = aws_iam_role.elasticbeanstalk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "elasticbeanstalk_webtier_attachment" {
  role       = aws_iam_role.elasticbeanstalk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "elasticbeanstalk_workertier_attachment" {
  role       = aws_iam_role.elasticbeanstalk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "ses_full_access_attachment" {
  role       = aws_iam_role.elasticbeanstalk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  role       = aws_iam_role.elasticbeanstalk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
