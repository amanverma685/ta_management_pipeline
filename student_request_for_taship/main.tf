resource "aws_iam_role" "iam_student_request_for_taship" {
  name = "iam_student_request_for_taship_${var.env}"

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


resource "aws_iam_policy" "student_request_for_taship_policy" {
  name        = "student_request_for_taship_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_student_request_for_taship" {
  role       = aws_iam_role.iam_student_request_for_taship.name
  policy_arn = aws_iam_policy.student_request_for_taship_policy.arn
}


resource "aws_lambda_function" "student_request_for_taship" {


  filename      = "../../student_request_for_taship/student_request_for_taship.zip"
  function_name = "student_request_for_taship"
  role          = aws_iam_role.iam_student_request_for_taship.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../student_request_for_taship/student_request_for_taship.zip")

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

resource "aws_lambda_permission" "aws_lambda_student_request_for_taship_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.student_request_for_taship.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.ta_request_form.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "ta_request_form" {
  name = "TA Request Management"
  description = "Apis to post ta form details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "ta_request_form" {
  name = "ta_request_form_authorizer"
  rest_api_id = aws_api_gateway_rest_api.ta_request_form.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource ta_request_form
resource "aws_api_gateway_resource" "ta_request_form" {
  rest_api_id = aws_api_gateway_rest_api.ta_request_form.id
  parent_id = aws_api_gateway_rest_api.ta_request_form.root_resource_id
  path_part = "ta_request"
}

# child resource : student_request_for_taship
resource "aws_api_gateway_resource" "student_request_for_taship" {
  rest_api_id = aws_api_gateway_rest_api.ta_request_form.id
  parent_id = aws_api_gateway_resource.ta_request_form.id
  path_part = "post_ta_request_details"
}


# student_request_for_taship : method
resource "aws_api_gateway_method" "student_request_for_taship" {
  rest_api_id = aws_api_gateway_rest_api.ta_request_form.id
  resource_id = aws_api_gateway_resource.student_request_for_taship.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.ta_request_form.id
}

#  lambda integration : student_request_for_taship-post-lambda
resource "aws_api_gateway_integration" "student_request_for_taship-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.ta_request_form.id
  resource_id = aws_api_gateway_method.student_request_for_taship.resource_id
  http_method = aws_api_gateway_method.student_request_for_taship.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.student_request_for_taship.invoke_arn
}


module "cors_student_request_for_taship" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.ta_request_form.id
  api_resource_id = aws_api_gateway_resource.student_request_for_taship.id
}

resource "aws_api_gateway_deployment" "ta_request_form_deployment" {
  depends_on= [aws_api_gateway_integration.student_request_for_taship-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.ta_request_form.id
  stage_name  = "${var.env}"
}




