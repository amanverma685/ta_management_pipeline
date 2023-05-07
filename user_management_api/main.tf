resource "aws_iam_role" "iam_update_user_details" {
  name = "iam_update_user_details_${var.env}"

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


resource "aws_iam_policy" "update_user_details_policy" {
  name        = "update_user_details_policy-${var.env}"
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
            "Action": ["cognito-idp:AdminUpdateUserAttributes","cognito-idp:AdminAddUserToGroup"],
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

resource "aws_iam_role_policy_attachment" "test_attach_update_user_details" {
  role       = aws_iam_role.iam_update_user_details.name
  policy_arn = aws_iam_policy.update_user_details_policy.arn
}


resource "aws_lambda_function" "update_user_details" {


  filename      = "../../user_management_api/update_user_details.zip"
  function_name = "update_user_details"
  role          = aws_iam_role.iam_update_user_details.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../user_management_api/update_user_details.zip")

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

resource "aws_lambda_permission" "aws_lambda_update_user_details_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_user_details.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.user_management_api.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "user_management_api" {
  name = "user Management"
  description = "Apis to get user details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "user_management_api" {
  name = "user_management_api_authorizer"
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource survey_metrics
resource "aws_api_gateway_resource" "survey_metrics" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  parent_id = aws_api_gateway_rest_api.user_management_api.root_resource_id
  path_part = "user_details"
}

# child resource : update_user_details
resource "aws_api_gateway_resource" "update_user_details" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  parent_id = aws_api_gateway_resource.survey_metrics.id
  path_part = "update_user"
}


# update_user_details : method
resource "aws_api_gateway_method" "update_user_details" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  resource_id = aws_api_gateway_resource.update_user_details.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.user_management_api.id
}

#  lambda integration : update_user_details-post-lambda
resource "aws_api_gateway_integration" "update_user_details-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  resource_id = aws_api_gateway_method.update_user_details.resource_id
  http_method = aws_api_gateway_method.update_user_details.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.update_user_details.invoke_arn
}

module "cors_update_user_details" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.user_management_api.id
  api_resource_id = aws_api_gateway_resource.update_user_details.id
}




# --------------------------------------------------------------- Get User Details ---------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "iam_get_user_details" {
  name = "iam_get_user_details_${var.env}"

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


resource "aws_iam_policy" "get_user_details_policy" {
  name        = "get_user_details_policy-${var.env}"
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
            "Action": ["cognito-idp:AdminUpdateUserAttributes","cognito-idp:AdminAddUserToGroup"],
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

resource "aws_iam_role_policy_attachment" "test_attach_get_user_details" {
  role       = aws_iam_role.iam_get_user_details.name
  policy_arn = aws_iam_policy.get_user_details_policy.arn
}


resource "aws_lambda_function" "get_user_details" {


  filename      = "../../user_management_api/get_user_details.zip"
  function_name = "get_user_details"
  role          = aws_iam_role.iam_get_user_details.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../user_management_api/get_user_details.zip")

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

resource "aws_lambda_permission" "aws_lambda_get_user_details_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user_details.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.user_management_api.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "user_management_api" {
  name = "user Management"
  description = "Apis to get user details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "user_management_api" {
  name = "user_management_api_authorizer"
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}


# child resource : get_user_details
resource "aws_api_gateway_resource" "get_user_details" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  parent_id = aws_api_gateway_resource.survey_metrics.id
  path_part = "get_user"
}


# get_user_details : method
resource "aws_api_gateway_method" "get_user_details" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  resource_id = aws_api_gateway_resource.get_user_details.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.user_management_api.id
}

#  lambda integration : get_user_details-post-lambda
resource "aws_api_gateway_integration" "get_user_details-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  resource_id = aws_api_gateway_method.get_user_details.resource_id
  http_method = aws_api_gateway_method.get_user_details.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.get_user_details.invoke_arn
}

module "cors_get_user_details" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.user_management_api.id
  api_resource_id = aws_api_gateway_resource.get_user_details.id
}

resource "aws_api_gateway_deployment" "user_management_api_deployment" {
  depends_on= [aws_api_gateway_integration.update_user_details-post-lambda,aws_api_gateway_integration.get_user_details-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.user_management_api.id
  stage_name  = "${var.env}"
}


