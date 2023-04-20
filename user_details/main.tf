resource "aws_iam_role" "iam_get_user_details_by_user_id" {
  name = "iam_get_user_details_by_user_id_${var.env}"

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


resource "aws_iam_policy" "get_user_details_by_user_id_policy" {
  name        = "get_user_details_by_user_id_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_get_user_details_by_user_id" {
  role       = aws_iam_role.iam_get_user_details_by_user_id.name
  policy_arn = aws_iam_policy.get_user_details_by_user_id_policy.arn
}


resource "aws_lambda_function" "get_user_details_by_user_id" {


  filename      = "../../user_details/get_user_details_by_user_id.zip"
  function_name = "get_user_details_by_user_id"
  role          = aws_iam_role.iam_get_user_details_by_user_id.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../user_details/get_user_details_by_user_id.zip")

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

resource "aws_lambda_permission" "aws_lambda_get_user_details_by_user_id_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user_details_by_user_id.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.user_management_api.execution_arn}/*/*"
}


# API Name
resource "aws_api_gateway_rest_api" "user_management_api" {
  name = "User Details"
  description = "Apis to get User details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "user_management_api" {
  name = "user_management_api_authorizer"
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}


# root resource survey_metrics
resource "aws_api_gateway_resource" "user_details" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  parent_id = aws_api_gateway_rest_api.user_management_api.root_resource_id
  path_part = "users"
}


# root resource survey_metrics
resource "aws_api_gateway_resource" "user_details_by_user_id" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  parent_id = aws_api_gateway_rest_api.user_details.id
  path_part = "user_details_by_user_id"
}


# child resource : get_user_details_by_user_id
resource "aws_api_gateway_resource" "get_user_details_by_user_id" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  parent_id = aws_api_gateway_resource.user_details_by_user_id.id
  path_part = "{user_id}"
}


# get_user_details_by_user_id : method
resource "aws_api_gateway_method" "GET_user_details" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  resource_id = aws_api_gateway_resource.get_user_details_by_user_id.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.user_management_api.id
}

#  lambda integration : get_user_details_by_user_id-post-lambda
resource "aws_api_gateway_integration" "get_user_details_by_user_id-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  resource_id = aws_api_gateway_method.GET_user_details.resource_id
  http_method = aws_api_gateway_method.GET_user_details.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.get_user_details_by_user_id.invoke_arn
}

module "cors_get_user_details_by_user_id" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.user_management_api.id
  api_resource_id = aws_api_gateway_resource.get_user_details_by_user_id.id
}

resource "aws_api_gateway_deployment" "user_management_api_deployment" {
  depends_on= [aws_api_gateway_integration.get_user_details_by_user_id-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  stage_name  = "${var.env}"
}


