locals {
  lambda_rekognition_zip_path = "${path.module}/python/rekognition.zip"
  lambda_redis_check_zip_path = "${path.module}/python/send_warning.zip"
}
