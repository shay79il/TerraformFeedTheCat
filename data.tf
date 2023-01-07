data "archive_file" "rekognition_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = local.lambda_rekognition_zip_path
}

data "archive_file" "redis_check_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = local.lambda_redis_check_zip_path
}