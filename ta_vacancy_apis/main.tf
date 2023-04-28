resource "aws_iam_role" "iam_add_ta_vacancy" {
  name = "iam_add_ta_vacancy_${var.env}"

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


resource "aws_iam_policy" "add_ta_vacancy_policy" {
  name        = "add_ta_vacancy_policy-${var.env}"
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
      "Action": ["codewhisperer:GenerateRecommendations"],
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

resource "aws_iam_role_policy_attachment" "test_attach_add_ta_vacancy" {
  role       = aws_iam_role.iam_add_ta_vacancy.name
  policy_arn = aws_iam_policy.add_ta_vacancy_policy.arn
}


resource "aws_lambda_function" "add_ta_vacancy" {


  filename      = "../../ta_vacancy_apis/add_ta_vacancy.zip"
  function_name = "add_ta_vacancy"
  role          = aws_iam_role.iam_add_ta_vacancy.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../ta_vacancy_apis/add_ta_vacancy.zip")

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

resource "aws_lambda_permission" "aws_lambda_add_ta_vacancy_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.add_ta_vacancy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.ta_vacancy_form.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "ta_vacancy_form" {
  name = "Ta Vacancy Management"
  description = "Apis to post ta form details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "ta_vacancy_form" {
  name = "ta_vacancy_form_authorizer"
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource ta_vacancy_form
resource "aws_api_gateway_resource" "ta_vacancy_form" {
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  parent_id = aws_api_gateway_rest_api.ta_vacancy_form.root_resource_id
  path_part = "ta_vacancy"
}

# child resource : add_ta_vacancy
resource "aws_api_gateway_resource" "add_ta_vacancy" {
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  parent_id = aws_api_gateway_resource.ta_vacancy_form.id
  path_part = "post_form_details"
}


# add_ta_vacancy : method
resource "aws_api_gateway_method" "add_ta_vacancy" {
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  resource_id = aws_api_gateway_resource.add_ta_vacancy.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.ta_vacancy_form.id
}

#  lambda integration : add_ta_vacancy-post-lambda
resource "aws_api_gateway_integration" "add_ta_vacancy-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  resource_id = aws_api_gateway_method.add_ta_vacancy.resource_id
  http_method = aws_api_gateway_method.add_ta_vacancy.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.add_ta_vacancy.invoke_arn
}

# ------------------------------ Get TA Vacancy List -------------------------------------------------
# ----------------------------------------------------------------------------------------------------

resource "aws_iam_role" "iam_get_ta_vacancy_list" {
  name = "iam_get_ta_vacancy_list_${var.env}"

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


resource "aws_iam_policy" "get_ta_vacancy_list_policy" {
  name        = "get_ta_vacancy_list_policy-${var.env}"
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
      "Action": ["codewhisperer:GenerateRecommendations"],
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

resource "aws_iam_role_policy_attachment" "test_attach_get_ta_vacancy_list" {
  role       = aws_iam_role.iam_get_ta_vacancy_list.name
  policy_arn = aws_iam_policy.get_ta_vacancy_list_policy.arn
}


resource "aws_lambda_function" "get_ta_vacancy_list" {


  filename      = "../../ta_vacancy_apis/get_ta_vacancy_list.zip"
  function_name = "get_ta_vacancy_list"
  role          = aws_iam_role.iam_get_ta_vacancy_list.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../ta_vacancy_apis/get_ta_vacancy_list.zip")

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

resource "aws_lambda_permission" "aws_lambda_get_ta_vacancy_list_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_ta_vacancy_list.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.ta_vacancy_form.execution_arn}/*/*"
}



# child resource : get_ta_vacancy_list
resource "aws_api_gateway_resource" "get_ta_vacancy_list" {
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  parent_id = aws_api_gateway_resource.ta_vacancy_form.id
  path_part = "get_ta_vacancy_list"
}


# get_ta_vacancy_list : method
resource "aws_api_gateway_method" "get_ta_vacancy_list" {
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  resource_id = aws_api_gateway_resource.get_ta_vacancy_list.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.ta_vacancy_form.id
}

#  lambda integration : get_ta_vacancy_list-post-lambda
resource "aws_api_gateway_integration" "get_ta_vacancy_list-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  resource_id = aws_api_gateway_method.get_ta_vacancy_list.resource_id
  http_method = aws_api_gateway_method.get_ta_vacancy_list.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.get_ta_vacancy_list.invoke_arn
}



module "cors_add_ta_vacancy" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.ta_vacancy_form.id
  api_resource_id = aws_api_gateway_resource.get_ta_vacancy_list.id
}


module "cors_list_ta_vacancy" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.ta_vacancy_form.id
  api_resource_id = aws_api_gateway_resource.add_ta_vacancy.id
}


resource "aws_api_gateway_deployment" "ta_vacancy_form_deployment" {
  depends_on= [aws_api_gateway_integration.add_ta_vacancy-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.ta_vacancy_form.id
  stage_name  = "${var.env}"
}


