# TerraformFeedTheCat

## There are

- ### 1 `S3 Bucket`

  - To upload files
  - Trigger lambda function each time a file is upload to check if it is a food for the cat with Rekognition service

- ### 1 `Elasticache Redis`

  - To save each timestamp of `food` file upload event
  - Save `bool` status variable to know if a warning email was sent

- ### 1 `CloudWatch event`

  - Triggers every 15 minutes `Lambda function` to check if the cat was feed else to check a warning email

- ### 1 `SES resource`

  - To send a warning email when 15 min have passed and the can was not feed
  - To send a `back to normal` email when the cat was feed

- ### 2 `Lambda function`

  - One `lambda function` which triggered each time a file is uploaded to the S3 bucket and send it to AWS Rekognition service to be able to know if the file is a proper food type for the cat.
  - Second `lambda function` which triggered every 15 min to check if the can was feed
