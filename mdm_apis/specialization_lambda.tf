data "archive_file" "specialization" {
  type        = "zip"
  source_file = "../../mdm_apis/specialization/main.js"
  output_path = "../../mdm_apis/specialization/specialization.zip"
}

resource "aws_lambda_function" "specialization" {
  function_name    = "get-specialization-list"
  filename         = "../../mdm_apis/specialization/specialization.zip"
  source_code_hash = data.archive_file.specialization.output_base64sha256

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "nodejs18.x"

  role = aws_iam_role.aws_iam_role_specialization.arn
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "aws_iam_role_specialization" {
  name               = "aws_iam_role_specialization"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "aws_lambda_specialization_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.specialization.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.master_data.execution_arn}/*/*"
}
