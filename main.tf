locals {
  lambda_rekognition_zip_path = "${path.module}/python/rekognition.zip"
  lambda_redis_check_zip_path = "${path.module}/python/send_warning.zip"
}

resource "random_string" "suffix" {
  length           = 8
  special          = false
}

##############################
#LAMBDA
##############################
resource "aws_iam_policy" "lambda" {
  name   = "aws_iam_policy_for_terraform_aws_lambda_role"
  policy = file("policies/lambda-policy.json")
}


resource "aws_iam_role" "lambda" {
  name                = "terraform_aws_lambda_role"
  assume_role_policy  = file("policies/lambda-assume-policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role        = aws_iam_role.lambda.name
  policy_arn  = aws_iam_policy.lambda.arn
}


resource "aws_lambda_function" "check_redis_variable" {
  filename      = local.lambda_redis_check_zip_path
  function_name = "check_redis_variable"
  role          = aws_iam_role.lambda.arn
  handler       = "send_warning.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      REDIS_CLUSTER_ID = aws_elasticache_cluster.redis.id
      EMAIL_ADDRESS    = "shay79il@gmail.com"
    }
  }
}

resource "aws_lambda_function" "rekognition_s3_upload" {
 filename                       = local.lambda_rekognition_zip_path
 function_name                  = "Lambda-Function"
 role                           = aws_iam_role.lambda.arn
 handler                        = "rekognition_s3_upload.lambda_handler"
 runtime                        = "python3.8"
 depends_on                     = [aws_iam_role_policy_attachment.lambda]
}


resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rekognition_s3_upload.function_name
  principal = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::${aws_s3_bucket.bucket.id}"
}

##################
# Creating s3 resource for invoking to lambda function
##################
resource "aws_s3_bucket" "bucket" {
  bucket = "cat-bucket-${random_string.suffix.result}"
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

##################
# Adding S3 bucket as trigger to my lambda and giving the permissions
##################
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = "${aws_s3_bucket.bucket.id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.rekognition_s3_upload.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"                                   
  }
}



##################
# Redis
##################
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "temp-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
}





##################
# CloudWatch Event
##################
resource "aws_cloudwatch_event_rule" "check_elasticache_variable" {
  name        = "check_redis_variable_15min"
  description = "Event rule to trigger Lambda function every 15 minutes"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "check_elasticache_variable" {
  rule = aws_cloudwatch_event_rule.check_elasticache_variable.name
  target_id = "check_redis_variable_15min_target"
  arn = aws_lambda_function.check_redis_variable.arn
}



##################
# SES Service
##################
resource "aws_ses_email_identity" "warning_email_identity" {
  email = "shay79il@gmail.com"
}
