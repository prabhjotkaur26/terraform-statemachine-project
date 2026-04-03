provider "aws" {
  region = "ap-south-1"
}
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-prabh26"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }
}
############################
# S3 BUCKET
############################
resource "aws_s3_bucket" "upload_bucket" {
  bucket = "prabhjot100-new-unique-2026"  # Unique name
}

resource "aws_s3_bucket_notification" "eventbridge" {
  bucket      = aws_s3_bucket.upload_bucket.id
  eventbridge = true
}

############################
# SNS TOPIC
############################
resource "aws_sns_topic" "topic" {
  name = "my-topic-new-2026"
}

############################
# IAM ROLE FOR LAMBDA
############################
resource "aws_iam_role" "lambda_role" {
  name = "lambda_exec_role_new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

############################
# LAMBDA FUNCTIONS
############################
resource "aws_lambda_function" "lambda1" {
  function_name = "lambda1-new"
  filename      = "lambda_zips/lambda1.zip"
  handler       = "lambda1.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "lambda2" {
  function_name = "lambda2-new"
  filename      = "lambda_zips/lambda2.zip"
  handler       = "lambda2.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "lambda3" {
  function_name = "lambda3-new"
  filename      = "lambda_zips/lambda3.zip"
  handler       = "lambda3.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
}
filename = "${path.module}/lambdas/lambda_zips/lambda1.zip"
filename = "${path.module}/lambdas/lambda_zips/lambda2.zip"
filename = "${path.module}/lambdas/lambda_zips/lambda3.zip"


############################
# STEP FUNCTION ROLE
############################
resource "aws_iam_role" "step_function_role" {
  name = "step_function_role_new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_function_policy" {
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          aws_lambda_function.lambda1.arn,
          aws_lambda_function.lambda2.arn,
          aws_lambda_function.lambda3.arn
        ]
      }
    ]
  })
}

############################
# STEP FUNCTION
############################
resource "aws_sfn_state_machine" "state_machine" {
  name     = "my-state-machine-new"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    StartAt = "Lambda1"
    States = {
      Lambda1 = {
        Type = "Task"
        Resource = aws_lambda_function.lambda1.arn
        Next = "ChoiceState"
      }

      ChoiceState = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.route"
            StringEquals = "email"
            Next = "Lambda2"
          },
          {
            Variable = "$.route"
            StringEquals = "sns"
            Next = "Lambda3"
          }
        ]
        Default = "Lambda3"
      }

      Lambda2 = {
        Type = "Task"
        Resource = aws_lambda_function.lambda2.arn
        End = true
      }

      Lambda3 = {
        Type = "Task"
        Resource = aws_lambda_function.lambda3.arn
        End = true
      }
    }
  })
}

############################
# EVENTBRIDGE ROLE
############################
resource "aws_iam_role" "eventbridge_role" {
  name = "eventbridge_role_new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "states:StartExecution"
      Resource = aws_sfn_state_machine.state_machine.arn
    }]
  })
}

############################
# EVENTBRIDGE RULE
############################
resource "aws_cloudwatch_event_rule" "s3_rule" {
  name = "s3-upload-rule-new"

  event_pattern = jsonencode({
    source = ["aws.s3"],
    detail-type = ["Object Created"],
    detail = {
      bucket = {
        name = [aws_s3_bucket.upload_bucket.bucket]
      }
    }
  })
}

############################
# EVENT TARGET (STEP FUNCTION)
############################
resource "aws_cloudwatch_event_target" "target" {
  rule      = aws_cloudwatch_event_rule.s3_rule.name
  target_id = "StepFunctionTargetNew"
  arn       = aws_sfn_state_machine.state_machine.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}
