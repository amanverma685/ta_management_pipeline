resource "aws_iam_role" "iam_sign_up_registration" {
  name = "iam_sign_up_registration_${var.env}"

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


resource "aws_iam_policy" "sign_up_registration_policy" {
  name        = "ses-sign_up_registration_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_sign_up_registration" {
  role       = aws_iam_role.iam_sign_up_registration.name
  policy_arn = aws_iam_policy.sign_up_registration_policy.arn
}


resource "aws_lambda_function" "sign_up_registration" {

  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.

  filename      = "../../authorisation_apis/sign_up_registration.zip"
  function_name = "sign_up_registration"
  role          = aws_iam_role.iam_sign_up_registration.arn
  handler       = "lambda_function.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"

  source_code_hash = filebase64sha256("../../authorisation_apis/sign_up_registration.zip")

  runtime = "python3.8"

  layers = ["${var.psycopg2_arn}"]

  environment {
    variables = {
      host = "${var.host}",
      database = "${var.database}",
      user = "${var.user}",
      password="${var.password}",
      port= "${var.port}",
      client_id= "${var.client_id}",
      group_name_student = "${var.group_name_student}",
      group_name_professor = "${var.group_name_professor}",
      user_pool_id ="${var.user_pool_id}",
      user_pool_arn ="${var.user_pool_arn}"
    }
  }
}

# Create the API Gateway
resource "aws_api_gateway_rest_api" "authorisation_api" {
  name = "Authorisation Post Confirmation"
  description = "authorisation_api API Gateway"
}

# Create the API Gateway Authorizer
resource "aws_api_gateway_authorizer" "authorisation_api" {
  name = "authorisation_api-authorizer"
  rest_api_id = aws_api_gateway_rest_api.authorisation_api.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# Create the API Gateway Resource
resource "aws_api_gateway_resource" "authorisation" {
  rest_api_id = aws_api_gateway_rest_api.authorisation_api.id
  parent_id = aws_api_gateway_rest_api.authorisation_api.root_resource_id
  path_part = "authorisation"
}

resource "aws_api_gateway_method" "sign_up_registration-post" {
  rest_api_id = aws_api_gateway_rest_api.authorisation_api.id
  resource_id = aws_api_gateway_resource.authorisation.id
  http_method = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "sign_up_registration-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.authorisation_api.id
  resource_id = aws_api_gateway_resource.authorisation.id
  http_method = aws_api_gateway_method.sign_up_registration-post.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.sign_up_registration.invoke_arn
}

module "cors_add_new_survey" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.authorisation_api.id
  api_resource_id = aws_api_gateway_resource.authorisation.id
}


resource "aws_api_gateway_deployment" "authorisation_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.authorisation_api.id
  stage_name  = "${var.env}"
}


