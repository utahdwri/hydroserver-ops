# ------------------------------------------------ #
# HydroServer Elastic Beanstalk Application        #
# ------------------------------------------------ #

resource "aws_elastic_beanstalk_application" "hydroserver_django_app" {
  name        = "hydroserver-${var.instance}"
  description = "HydroServer Django Application on Elastic Beanstalk"
}

# ------------------------------------------------ #
# HydroServer Elastic Beanstalk Environment        #
# ------------------------------------------------ #

resource "aws_elastic_beanstalk_environment" "hydroserver_django_env" {
  name                = "hydroserver-${var.instance}-env"
  application         = aws_elastic_beanstalk_application.hydroserver_django_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.11 running Python 3.8"

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfileS3"
    value     = aws_iam_role.elasticbeanstalk_role.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ADMIN_EMAIL"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ALLOWED_HOSTS"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_STORAGE_BUCKET_NAME"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DEBUG"
    value     = "True"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DEPLOYED"
    value     = "True"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OAUTH_GOOGLE_CLIENT"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OAUTH_GOOGLE_SECRET"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OAUTH_HYDROSHARE_CLIENT"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OAUTH_HYDROSHARE_SECRET"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OAUTH_ORCID_CLIENT"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OAUTH_ORCID_SECRET"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PROXY_BASE_URL"
    value     = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SECRET_KEY"
    value     = ""
  }
}

# ------------------------------------------------ #
# HydroServer Elastic Beanstalk IAM Role           #
# ------------------------------------------------ #

resource "aws_iam_role" "elasticbeanstalk_role" {
  name = "hydroserver-${var.instance}-eb-iam-role"
  
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "eb_s3_policy" {
  name        = "hydroserver-${var.instance}-eb-s3-access-policy"
  description = "Policy for S3 storage bucket access"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::hydroserver-${var.instance}-storage",
        "arn:aws:s3:::hydroserver-${var.instance}-storage/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  policy_arn = aws_iam_policy.eb_s3_policy.arn
  role       = aws_iam_role.elasticbeanstalk_role.name
}
