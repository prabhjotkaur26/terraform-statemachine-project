import boto3

s3 = boto3.client('s3')
sns = boto3.client('sns')
ssm = boto3.client('ssm')

def lambda_handler(event, context):
    bucket = event['bucket']
    key = event['key']

    #  Get SNS ARN from SSM
    param = ssm.get_parameter(Name="/myapp/sns/topic_arn")
    topic_arn = param['Parameter']['Value']

    #  Get metadata
    response = s3.head_object(Bucket=bucket, Key=key)
    metadata = response.get('Metadata', {})

    message = f"""
File Uploaded!

Bucket: {bucket}
Key: {key}

Metadata:
{metadata}
"""

    sns.publish(
        TopicArn=topic_arn,
        Message=message,
        Subject="S3 Metadata Notification"
    )

    return {
        "statusCode": 200
    }