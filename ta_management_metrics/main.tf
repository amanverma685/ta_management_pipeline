resource "aws_iam_role" "iam_professor_dashboard_metrics" {
  name = "iam_professor_dashboard_metrics_${var.env}"

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
# Test Changes

resource "aws_iam_policy" "professor_dashboard_metrics_policy" {
  name        = "professor_dashboard_metrics_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_professor_dashboard_metrics" {
  role       = aws_iam_role.iam_professor_dashboard_metrics.name
  policy_arn = aws_iam_policy.professor_dashboard_metrics_policy.arn
}


resource "aws_lambda_function" "professor_dashboard_metrics" {


  filename      = "../../ta_management_metrics/professor_dashboard_metrics.zip"
  function_name = "professor_dashboard_metrics"
  role          = aws_iam_role.iam_professor_dashboard_metrics.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../ta_management_metrics/professor_dashboard_metrics.zip")

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

resource "aws_lambda_permission" "aws_lambda_professor_dashboard_metrics_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.professor_dashboard_metrics.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.accept_reject_by_professor.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "accept_reject_by_professor" {
  name = "TA Management Metrics"
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
  path_part = "ta_management_metrics"
}

# child resource : professor_dashboard_metrics
resource "aws_api_gateway_resource" "professor_dashboard_metrics" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  parent_id = aws_api_gateway_resource.accept_reject_by_professor.id
  path_part = "professor_dashboard_metrics"
}


# professor_dashboard_metrics : method
resource "aws_api_gateway_method" "POST_professor_dashboard_metrics" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  resource_id = aws_api_gateway_resource.professor_dashboard_metrics.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.accept_reject_by_professor.id
}

#  lambda integration : professor_dashboard_metrics-post-lambda
resource "aws_api_gateway_integration" "professor_dashboard_metrics-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  resource_id = aws_api_gateway_method.POST_professor_dashboard_metrics.resource_id
  http_method = aws_api_gateway_method.POST_professor_dashboard_metrics.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.professor_dashboard_metrics.invoke_arn
}

module "cors_professor_dashboard_metrics" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.accept_reject_by_professor.id
  api_resource_id = aws_api_gateway_resource.professor_dashboard_metrics.id
}

# -----------------------------------------------------Student Metrics--------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "iam_student_dashboard_metrics" {
  name = "iam_student_dashboard_metrics_${var.env}"

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


resource "aws_iam_policy" "student_dashboard_metrics_policy" {
  name        = "student_dashboard_metrics_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_student_dashboard_metrics" {
  role       = aws_iam_role.iam_student_dashboard_metrics.name
  policy_arn = aws_iam_policy.student_dashboard_metrics_policy.arn
}


resource "aws_lambda_function" "student_dashboard_metrics" {


  filename      = "../../ta_management_metrics/student_dashboard_metrics.zip"
  function_name = "student_dashboard_metrics"
  role          = aws_iam_role.iam_student_dashboard_metrics.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../ta_management_metrics/student_dashboard_metrics.zip")

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

resource "aws_lambda_permission" "aws_lambda_student_dashboard_metrics_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.student_dashboard_metrics.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.accept_reject_by_professor.execution_arn}/*/*"
}


# child resource : student_dashboard_metrics
resource "aws_api_gateway_resource" "student_dashboard_metrics" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  parent_id = aws_api_gateway_resource.accept_reject_by_professor.id
  path_part = "student_dashboard_metrics"
}


# student_dashboard_metrics : method
resource "aws_api_gateway_method" "POST_student_dashboard_metrics" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  resource_id = aws_api_gateway_resource.student_dashboard_metrics.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.accept_reject_by_professor.id
}

#  lambda integration : student_dashboard_metrics-post-lambda
resource "aws_api_gateway_integration" "student_dashboard_metrics-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  resource_id = aws_api_gateway_method.POST_student_dashboard_metrics.resource_id
  http_method = aws_api_gateway_method.POST_student_dashboard_metrics.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.student_dashboard_metrics.invoke_arn
}

module "cors_student_dashboard_metrics" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.accept_reject_by_professor.id
  api_resource_id = aws_api_gateway_resource.student_dashboard_metrics.id
}


resource "aws_api_gateway_deployment" "accept_reject_by_professor_deployment" {
  depends_on= [aws_api_gateway_integration.professor_dashboard_metrics-post-lambda,aws_api_gateway_integration.student_dashboard_metrics-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.accept_reject_by_professor.id
  stage_name  = "${var.env}"
}


