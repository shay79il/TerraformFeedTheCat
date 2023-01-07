import boto3
from redis import Redis

s3 = boto3.client('s3')
rekognition = boto3.client('rekognition')
redis = Redis(host='temp-cluster', port=6379, db=0)
email = "shay79il@gmail.com"

def send_email(massage):
  ses = boto3.client('ses')
  response = ses.send_email(
      Source=email,
      Destination={
          'ToAddresses': [email],
      },
      Message={
          'Subject': {
              'Data': {massage}
          },
          'Body': {
              'Text': {
                  'Data': {massage}
              }
          }
      }
  )



def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    response = s3.get_object(Bucket=bucket, Key=key)
    file_content = response['Body'].read()

    response = rekognition.detect_labels(Image={'Bytes': file_content})

    for label in response['Labels']:
        if label['Name'].lower() == 'food' and label['Confidence'] >= 90:
            redis.set('last_timestamp', context.timestamp)
            if redis.get('email_sent') == 1:
              redis.set('email_sent', 0)
              send_email("back to normal")
            break

















import json
import urllib.parse
import boto3
from datetime import datetime

print('Loading function')

rekognition_client = boto3.client('rekognition')

s3 = boto3.client('s3')


def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))

    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    try:
      response = rekognition_client.detect_moderation_labels(
        Image = {'S3Object': {'Bucket': bucket, 'Name': key}}
      )

      for label in response['ModerationLabels']:
        confidence = float(label['Confidence'])
        label = label["Name"]
        if 'Food' in label and confidence >= 0.9:
          print("FoodFound")
      return response['ContentType']
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e
      
      
      
      
      
dynamodb = boto3.resource("dynamodb")
image_labels_table = dynamodb.Table(os.environ["IMAGE_LABELS_TABLE"])


def event_handler(event, context):

    time = datetime.now()
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    response = rekognition_client.detect_moderation_labels(
        Image={'S3Object': {'Bucket': bucket, 'Name': key}})

    for label in response['ModerationLabels']:
        confidence = float(label['Confidence'])
        label = label["Name"]
        if 'Food' in label and 
        image_labels_table.put_item(Item={
            "image_key": key,
            "image_label": label,
            "parent_label": parent_label,
            "confidence": confidence
        })