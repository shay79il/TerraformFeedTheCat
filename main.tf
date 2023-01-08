resource "random_string" "suffix" {
  length           = var.random_string_length
  special          = var.random_string_special
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
  runtime       = var.lambda_function_runtime

  environment {
    variables = {
      REDIS_CLUSTER_ID = aws_elasticache_cluster.redis.id
      EMAIL_ADDRESS    = var.email
    }
  }
}

resource "aws_lambda_function" "rekognition_s3_upload" {
 filename                       = local.lambda_rekognition_zip_path
 function_name                  = "Lambda-Function"
 role                           = aws_iam_role.lambda.arn
 handler                        = "rekognition_s3_upload.lambda_handler"
 runtime                        = var.lambda_function_runtime
 depends_on                     = [aws_iam_role_policy_attachment.lambda]
}


resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rekognition_s3_upload.function_name
  principal = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::${aws_s3_bucket.bucket.id}"
}

######################################################
# Creating s3 resource for invoking to lambda function
######################################################
resource "aws_s3_bucket" "bucket" {
  bucket = "cat-bucket-${random_string.suffix.result}"
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = var.s3_bucket_acl
}

##################
# Adding S3 bucket as trigger to my lambda and giving the permissions
##################
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = "${aws_s3_bucket.bucket.id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.rekognition_s3_upload.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = var.filter_suffix                                  
  }
}



##################
# Redis
##################
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.elasticache_cluster_id
  engine               = var.elasticache_cluster_engine
  node_type            = var.elasticache_cluster_node_type
  num_cache_nodes      = var.elasticache_cluster_num_cache_nodes
  parameter_group_name = var.elasticache_cluster_group_name
  engine_version       = var.elasticache_cluster_engine_version
  port                 = var.elasticache_cluster_port
}





##################
# CloudWatch Event
##################
resource "aws_cloudwatch_event_rule" "check_elasticache_variable" {
  name        = "check_redis_variable_15min"
  description = "Event rule to trigger Lambda function every 15 minutes"
  schedule_expression = "rate(${var.cloudwatch_event_rule_rate} minutes)"
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
  email = var.email
}
