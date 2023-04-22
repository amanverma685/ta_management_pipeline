resource "aws_iam_role" "iam_is_user_registered" {
  name = "iam_is_user_registered_${var.env}"

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


resource "aws_iam_policy" "is_user_registered_policy" {
  name        = "is_user_registered_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_is_user_registered" {
  role       = aws_iam_role.iam_is_user_registered.name
  policy_arn = aws_iam_policy.is_user_registered_policy.arn
}


resource "aws_lambda_function" "is_user_registered" {


  filename      = "../../is_user_registered/is_user_registered.zip"
  function_name = "is_user_registered"
  role          = aws_iam_role.iam_is_user_registered.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../is_user_registered/is_user_registered.zip")

  runtime = "python3.8"

  layers = ["${var.psycopg2_arn}"]

  environment {
    variables = {
      host = "${var.host}",
      database = "${var.database}",
      user = "${var.user}",
      password="${var.password}",
      port= "${var.port}"
    }
  }
}

resource "aws_lambda_permission" "aws_lambda_is_user_registered_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.is_user_registered.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.user_registration.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "user_registration" {
  name = "User Registration"
  description = "Api to get user details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "user_registration" {
  name = "user_registration_authorizer"
  rest_api_id = aws_api_gateway_rest_api.user_registration.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource user_registration
resource "aws_api_gateway_resource" "user_registration" {
  rest_api_id = aws_api_gateway_rest_api.user_registration.id
  parent_id = aws_api_gateway_rest_api.user_registration.root_resource_id
  path_part = "user_registration"
}

# child resource : is_user_registered
resource "aws_api_gateway_resource" "is_user_registered" {
  rest_api_id = aws_api_gateway_rest_api.user_registration.id
  parent_id = aws_api_gateway_resource.user_registration.id
  path_part = "{user_id}"
}


# is_user_registered : method
resource "aws_api_gateway_method" "POST_is_user_registered" {
  rest_api_id = aws_api_gateway_rest_api.user_registration.id
  resource_id = aws_api_gateway_resource.is_user_registered.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.user_registration.id
}

#  lambda integration : is_user_registered-post-lambda
resource "aws_api_gateway_integration" "is_user_registered-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.user_registration.id
  resource_id = aws_api_gateway_method.POST_is_user_registered.resource_id
  http_method = aws_api_gateway_method.POST_is_user_registered.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.is_user_registered.invoke_arn
}

module "cors_is_user_registered" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.user_registration.id
  api_resource_id = aws_api_gateway_resource.is_user_registered.id
}


resource "aws_api_gateway_deployment" "user_registration_deployment" {
  depends_on= [aws_api_gateway_integration.is_user_registered-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.user_registration.id
  stage_name  = "${var.env}"
}


