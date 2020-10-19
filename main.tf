provider "aws" {
}

# Lambda function

resource "random_id" "id" {
  byte_length = 8
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "/tmp/${random_id.id.hex}-lambda.zip"
	source {
    content  = file("index.js")
    filename = "index.js"
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = "api_example-${random_id.id.hex}-function"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs12.x"
  role    = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      PARAMETER  = aws_ssm_parameter.test_secret.name
    }
  }
}

resource "aws_ssm_parameter" "test_secret" {
	name = "test-secret"
	type = "SecureString"
  value = "test value"
}

data "aws_iam_policy_document" "lambda_exec_role_policy" {
  statement {
    actions = [
			"ssm:GetParameter",
    ]
    resources = [
      aws_ssm_parameter.test_secret.arn
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "lambda_exec_role" {
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_exec_role_policy.json
}

resource "aws_iam_role" "lambda_exec" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "lambda.amazonaws.com"
	  },
	  "Effect": "Allow"
	}
  ]
}
EOF
}

# API Gateway

resource "aws_apigatewayv2_api" "api" {
  name          = "api-${random_id.id.hex}"
  protocol_type = "HTTP"
  target        = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

output "url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}
