import boto3
from redis import Redis

redis = Redis(host='temp-cluster', port=6379, db=0)
email = "shay79il@gmail.com"

def send_warning():
  redis.set('email_sent', 1)
  ses = boto3.client('ses')
  email = ses.get
  response = ses.send_email(
      Source=email,
      Destination={
          'ToAddresses': [email],
      },
      Message={
          'Subject': {
              'Data': 'Feed CAT'
          },
          'Body': {
              'Text': {
                  'Data': 'Feed CAT'
              }
          }
      }
  )


def lambda_handler(event, context):
  last_timestamp = redis.get('last_timestamp')
  if context.timestamp - last_timestamp > 15:
    if redis.get('email_sent') == 1:
      return
    else:
      send_warning()