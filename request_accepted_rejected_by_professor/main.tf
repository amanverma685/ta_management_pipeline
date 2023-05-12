resource "aws_iam_role" "iam_request_accepted_rejected_by_professor" {
  name = "iam_request_accepted_rejected_by_professor_${var.env}"

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


resource "aws_iam_policy" "request_accepted_rejected_by_professor_policy" {
  name        = "request_accepted_rejected_by_professor_policy-${var.env}"
  description = "A ses policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "*"
    },
    {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
    },
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test_attach_request_accepted_rejected_by_professor" {
  role       = aws_iam_role.iam_request_accepted_rejected_by_professor.name
  policy_arn = aws_iam_policy.request_accepted_rejected_by_professor_policy.arn
}


resource "aws_lambda_function" "request_accepted_rejected_by_professor" {


  filename      = "../../request_accepted_rejected_by_professor/request_accepted_rejected_by_professor.zip"
  function_name = "request_accepted_rejected_by_professor"
  role          = aws_iam_role.iam_request_accepted_rejected_by_professor.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../request_accepted_rejected_by_professor/request_accepted_rejected_by_professor.zip")

  runtime = "python3.8"

  layers = ["${var.psycopg2_arn}"]

  environment {
    variables = {
      host = "${var.host}",
      database = "${var.database}",
      user = "${var.user}",
      password="${var.password}",
      port= "${var.port}",
      user_pool_id ="${var.user_pool_id}"
    }
  }
}

resource "aws_lambda_permission" "aws_lambda_request_accepted_rejected_by_professor_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.request_accepted_rejected_by_professor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.accept_reject_by_professor.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "accept_reject_by_professor" {
  name = "Request Response"
  description = "Api to Accept and reject "
}

# Authorizer
resource "aws_api_gateway_authorizer" "accept_reject_by_professor" {
  name = "accept_reject_by_professor_authorizer"
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource accept_reject_by_professor
resource "aws_api_gateway_resource" "accept_reject_by_professor" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  parent_id = aws_api_gateway_rest_api.accept_reject_by_professor.root_resource_id
  path_part = "accept_reject_by_professor"
}

# child resource : request_accepted_rejected_by_professor
resource "aws_api_gateway_resource" "request_accepted_rejected_by_professor" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  parent_id = aws_api_gateway_resource.accept_reject_by_professor.id
  path_part = "accpet_reject"
}


# request_accepted_rejected_by_professor : method
resource "aws_api_gateway_method" "POST_request_accepted_rejected_by_professor" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  resource_id = aws_api_gateway_resource.request_accepted_rejected_by_professor.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.accept_reject_by_professor.id
}

#  lambda integration : request_accepted_rejected_by_professor-post-lambda
resource "aws_api_gateway_integration" "request_accepted_rejected_by_professor-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  resource_id = aws_api_gateway_method.POST_request_accepted_rejected_by_professor.resource_id
  http_method = aws_api_gateway_method.POST_request_accepted_rejected_by_professor.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.request_accepted_rejected_by_professor.invoke_arn
}

module "cors_request_accepted_rejected_by_professor" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.accept_reject_by_professor.id
  api_resource_id = aws_api_gateway_resource.request_accepted_rejected_by_professor.id
}


resource "aws_api_gateway_deployment" "accept_reject_by_professor_deployment" {
  depends_on= [aws_api_gateway_integration.request_accepted_rejected_by_professor-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  stage_name  = "${var.env}"
}


