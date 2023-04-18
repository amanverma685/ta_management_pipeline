resource "aws_iam_role" "iam_get_survey_count_by_status_per_month" {
  name = "iam_get_survey_count_by_status_per_month_${var.env}"

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


resource "aws_iam_policy" "get_survey_count_by_status_per_month_policy" {
  name        = "get_survey_count_by_status_per_month_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_get_survey_count_by_status_per_month" {
  role       = aws_iam_role.iam_get_survey_count_by_status_per_month.name
  policy_arn = aws_iam_policy.get_survey_count_by_status_per_month_policy.arn
}


resource "aws_lambda_function" "get_survey_count_by_status_per_month" {


  filename      = "../../get_survey_metrics/get_survey_count_by_status_per_month.zip"
  function_name = "get_survey_count_by_status_per_month"
  role          = aws_iam_role.iam_get_survey_count_by_status_per_month.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../get_survey_metrics/get_survey_count_by_status_per_month.zip")

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

resource "aws_lambda_permission" "aws_lambda_get_survey_count_by_status_per_month_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_survey_count_by_status_per_month.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.survey_metrics_api.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "survey_metrics_api" {
  name = "Survey Metrics"
  description = "Survay Matrices to get details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "survey_metrics_api" {
  name = "survey_metrics_api_authorizer"
  rest_api_id = aws_api_gateway_rest_api.survey_metrics_api.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource survey_metrics
resource "aws_api_gateway_resource" "survey_metrics" {
  rest_api_id = aws_api_gateway_rest_api.survey_metrics_api.id
  parent_id = aws_api_gateway_rest_api.survey_metrics_api.root_resource_id
  path_part = "survey_metrics"
}

# child resource : get_survey_count_by_status_per_month
resource "aws_api_gateway_resource" "get_survey_count_by_status_per_month" {
  rest_api_id = aws_api_gateway_rest_api.survey_metrics_api.id
  parent_id = aws_api_gateway_resource.survey_metrics.id
  path_part = "get_surveys_count"
}


# get_survey_count_by_status_per_month : method
resource "aws_api_gateway_method" "POST" {
  rest_api_id = aws_api_gateway_rest_api.survey_metrics_api.id
  resource_id = aws_api_gateway_resource.get_survey_count_by_status_per_month.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.survey_metrics_api.id
}

#  lambda integration : get_survey_count_by_status_per_month-post-lambda
resource "aws_api_gateway_integration" "get_survey_count_by_status_per_month-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.survey_metrics_api.id
  resource_id = aws_api_gateway_method.POST.resource_id
  http_method = aws_api_gateway_method.POST.http_method
  
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.get_survey_count_by_status_per_month.invoke_arn
}

module "cors_get_survey_count_by_status_per_month" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.survey_metrics_api.id
  api_resource_id = aws_api_gateway_resource.get_survey_count_by_status_per_month.id
}


resource "aws_api_gateway_deployment" "survey_metrics_api_deployment" {
  depends_on= [aws_api_gateway_integration.get_survey_count_by_status_per_month-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.survey_metrics_api.id
  stage_name  = "${var.env}"
}


