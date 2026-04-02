import boto3

ssm = boto3.client('ssm')

def lambda_handler(event, context):
    bucket = event['bucket']
    key = event['key']

    # Get notification type from SSM
    param = ssm.get_parameter(Name="/myapp/notification_type")
    notification_type = param['Parameter']['Value']

    return {
        "bucket": bucket,
        "key": key,
        "notification_type": notification_type
    }