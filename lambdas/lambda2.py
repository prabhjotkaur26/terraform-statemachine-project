import boto3
import urllib.parse

s3 = boto3.client('s3')
ses = boto3.client('ses')
def lambda_handler(event, context):
    bucket = event['bucket']
    key = urllib.parse.unquote_plus(event['key'])

    response = s3.head_object(Bucket=bucket, Key=key)

    message = f"""
File Uploaded!

Bucket: {bucket}
Key: {key}

ContentType: {response.get('ContentType')}
Size: {response.get('ContentLength')}
LastModified: {response.get('LastModified')}

Custom Metadata:
{response.get('Metadata', {})}
"""

    ses.send_email(
        Source='prabh008968@email.com',
        Destination={'ToAddresses': ['prabh008968@email.com']},
        Message={
            'Subject': {'Data': 'S3 Metadata Notification'},
            'Body': {'Text': {'Data': message}}
        }
    )

    return {"statusCode": 200}