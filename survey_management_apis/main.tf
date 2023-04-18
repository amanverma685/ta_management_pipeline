resource "aws_iam_role" "iam_add_new_survey" {
  name = "iam_add_new_survey_${var.env}"

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


resource "aws_iam_policy" "add_new_survey_policy" {
  name        = "add_new_survey_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_add_new_survey" {
  role       = aws_iam_role.iam_add_new_survey.name
  policy_arn = aws_iam_policy.add_new_survey_policy.arn
}


resource "aws_lambda_function" "add_new_survey" {


  filename      = "../../survey_management_apis/add_new_survey.zip"
  function_name = "add_new_survey"
  role          = aws_iam_role.iam_add_new_survey.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../survey_management_apis/add_new_survey.zip")

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

resource "aws_lambda_permission" "aws_lambda_add_new_survey_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.add_new_survey.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.survey_management_api.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "survey_management_api" {
  name = "Survey Management"
  description = "Survay Management API Gateway"
}

# Authorizer
resource "aws_api_gateway_authorizer" "survey_management_api" {
  name = "survey_management_api_authorizer"
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource survey_management
resource "aws_api_gateway_resource" "survey_management" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  parent_id = aws_api_gateway_rest_api.survey_management_api.root_resource_id
  path_part = "survey_management"
}

# child resource : add_new_survey
resource "aws_api_gateway_resource" "add_new_survey" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  parent_id = aws_api_gateway_resource.survey_management.id
  path_part = "add_new_survey"
}


# add_new_survey : method
resource "aws_api_gateway_method" "POST" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_resource.add_new_survey.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.survey_management_api.id
}

#  lambda integration : add_new_survey-post-lambda
resource "aws_api_gateway_integration" "add_new_survey-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_method.POST.resource_id
  http_method = aws_api_gateway_method.POST.http_method
  
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.add_new_survey.invoke_arn
}

module "cors_add_new_survey" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.survey_management_api.id
  api_resource_id = aws_api_gateway_resource.add_new_survey.id
}

# -------------------------------------------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "iam_list_all_survey" {
  name = "iam_list_all_survey_${var.env}"

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


resource "aws_iam_policy" "list_all_survey_policy" {
  name        = "ses-list_all_survey_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_list_all_survey" {
  role       = aws_iam_role.iam_list_all_survey.name
  policy_arn = aws_iam_policy.list_all_survey_policy.arn
}


resource "aws_lambda_function" "list_all_surveys" {

  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.

  filename      = "../../survey_management_apis/list_all_surveys.zip"
  function_name = "list_all_surveys"
  role          = aws_iam_role.iam_list_all_survey.arn
  handler       = "lambda_function.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"

  source_code_hash = filebase64sha256("../../survey_management_apis/list_all_surveys.zip")

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

resource "aws_lambda_permission" "aws_lambda_list_all_surveys_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_all_surveys.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.survey_management_api.execution_arn}/*/*"
}

# child resource : add_new_survey
resource "aws_api_gateway_resource" "list_all_surveys" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  parent_id = aws_api_gateway_resource.survey_management.id
  path_part = "list_all_surveys"
}

# list_all_surveys : method
resource "aws_api_gateway_method" "GET" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_resource.list_all_surveys.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.survey_management_api.id
}

#  lambda integration : list_all_surveys-post-lambda
resource "aws_api_gateway_integration" "list_all_surveys-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_method.GET.resource_id
  http_method = aws_api_gateway_method.GET.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.list_all_surveys.invoke_arn
}

module "cors_list_all_surveys" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.survey_management_api.id
  api_resource_id = aws_api_gateway_resource.list_all_surveys.id
}

# -----------------------------------Publish Survey---------------------------------------------------------------------------------------------------------
# -----------------------------------Publish Survey---------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "iam_publish_survey" {
  name = "iam_publish_survey_${var.env}"

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


resource "aws_iam_policy" "publish_survey_policy" {
  name        = "ses-publish_survey_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_publish_survey" {
  role       = aws_iam_role.iam_publish_survey.name
  policy_arn = aws_iam_policy.publish_survey_policy.arn
}


resource "aws_lambda_function" "publish_survey" {


  filename      = "../../survey_management_apis/publish_survey.zip"
  function_name = "publish_survey"
  role          = aws_iam_role.iam_publish_survey.arn
  handler       = "lambda_function.lambda_handler"


  source_code_hash = filebase64sha256("../../survey_management_apis/publish_survey.zip")

  runtime = "python3.8"

  layers = ["${var.psycopg2_arn}"]

  environment {
    variables = {
      host = "${var.host}",
      database = "${var.database}",
      user = "${var.user}",
      password ="${var.password}",
      port = "${var.port}"
    }
  }
}

resource "aws_lambda_permission" "aws_lambda_publish_survey_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.publish_survey.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.survey_management_api.execution_arn}/*/*"
}

# child resource : add_new_survey
resource "aws_api_gateway_resource" "publish_survey" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  parent_id = aws_api_gateway_resource.survey_management.id
  path_part = "publish_survey"
}

# publish_survey : method
resource "aws_api_gateway_method" "POST_publish_survey" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_resource.publish_survey.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.survey_management_api.id
}


#  lambda integration : publish_survey-post-lambda
resource "aws_api_gateway_integration" "publish_survey-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_method.POST_publish_survey.resource_id
  http_method = aws_api_gateway_method.POST_publish_survey.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.publish_survey.invoke_arn
}


module "cors_publish_survey" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.survey_management_api.id
  api_resource_id = aws_api_gateway_resource.publish_survey.id
}



# -----------------------------------Search from Survey List---------------------------------------------------------------------------------------------------------
# -----------------------------------Search from Survey List---------------------------------------------------------------------------------------------------------


resource "aws_iam_role" "iam_search_from_survey_data" {
  name = "iam_search_from_survey_data_${var.env}"

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


resource "aws_iam_policy" "search_from_survey_data_policy" {
  name        = "ses-search_from_survey_data_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_search_from_survey_data" {
  role       = aws_iam_role.iam_search_from_survey_data.name
  policy_arn = aws_iam_policy.search_from_survey_data_policy.arn
}


resource "aws_lambda_function" "search_from_survey_data" {


  filename      = "../../survey_management_apis/search_from_survey_data.zip"
  function_name = "search_from_survey_data"
  role          = aws_iam_role.iam_search_from_survey_data.arn
  handler       = "lambda_function.lambda_handler"


  source_code_hash = filebase64sha256("../../survey_management_apis/search_from_survey_data.zip")

  runtime = "python3.8"

  layers = ["${var.psycopg2_arn}"]

  environment {
    variables = {
      host = "${var.host}",
      database = "${var.database}",
      user = "${var.user}",
      password ="${var.password}",
      port = "${var.port}"
    }
  }
}

resource "aws_lambda_permission" "aws_lambda_search_from_survey_data_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.search_from_survey_data.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.survey_management_api.execution_arn}/*/*"
}

# child resource : add_new_survey
resource "aws_api_gateway_resource" "search_from_survey_data" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  parent_id = aws_api_gateway_resource.survey_management.id
  path_part = "search_from_survey_data"
}

# search_from_survey_data : method
resource "aws_api_gateway_method" "POST_search_from_survey_data" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_resource.search_from_survey_data.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.survey_management_api.id
}


#  lambda integration : search_from_survey_data-post-lambda
resource "aws_api_gateway_integration" "search_from_survey_data-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_method.POST_search_from_survey_data.resource_id
  http_method = aws_api_gateway_method.POST_search_from_survey_data.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.search_from_survey_data.invoke_arn
}


module "cors_search_from_survey_data" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.survey_management_api.id
  api_resource_id = aws_api_gateway_resource.search_from_survey_data.id
}




# -----------------------------------Get Survey Details By Survey Id---------------------------------------------------------------------------------------------------------
# -----------------------------------Get Survey Details By Survey Id---------------------------------------------------------------------------------------------------------


resource "aws_iam_role" "iam_get_survey_details_by_survey_id" {
  name = "iam_get_survey_details_by_survey_id_${var.env}"

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


resource "aws_iam_policy" "get_survey_details_by_survey_id_policy" {
  name        = "ses-get_survey_details_by_survey_id_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_get_survey_details_by_survey_id" {
  role       = aws_iam_role.iam_get_survey_details_by_survey_id.name
  policy_arn = aws_iam_policy.get_survey_details_by_survey_id_policy.arn
}


resource "aws_lambda_function" "get_survey_details_by_survey_id" {


  filename      = "../../survey_management_apis/get_survey_details_by_survey_id.zip"
  function_name = "get_survey_details_by_survey_id"
  role          = aws_iam_role.iam_get_survey_details_by_survey_id.arn
  handler       = "lambda_function.lambda_handler"


  source_code_hash = filebase64sha256("../../survey_management_apis/get_survey_details_by_survey_id.zip")

  runtime = "python3.8"

  layers = ["${var.psycopg2_arn}"]

  environment {
    variables = {
      host = "${var.host}",
      database = "${var.database}",
      user = "${var.user}",
      password ="${var.password}",
      port = "${var.port}"
    }
  }
}

resource "aws_lambda_permission" "aws_lambda_get_survey_details_by_survey_id_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_survey_details_by_survey_id.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.survey_management_api.execution_arn}/*/*"
}


resource "aws_api_gateway_resource" "get_survey_details" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  parent_id = aws_api_gateway_resource.survey_management.id
  path_part = "get_survey_details"
}

# child resource : add_new_survey
resource "aws_api_gateway_resource" "get_survey_details_by_survey_id" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  parent_id = aws_api_gateway_resource.get_survey_details.id
  path_part = "{survey_id}"
}

# get_survey_details_by_survey_id : method
resource "aws_api_gateway_method" "GET_get_survey_details_by_survey_id" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_resource.get_survey_details_by_survey_id.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.survey_management_api.id
}


#  lambda integration : get_survey_details_by_survey_id-post-lambda
resource "aws_api_gateway_integration" "get_survey_details_by_survey_id-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  resource_id = aws_api_gateway_method.GET_get_survey_details_by_survey_id.resource_id
  http_method = aws_api_gateway_method.GET_get_survey_details_by_survey_id.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.get_survey_details_by_survey_id.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

}


module "cors_get_survey_details_by_survey_id" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.survey_management_api.id
  api_resource_id = aws_api_gateway_resource.get_survey_details_by_survey_id.id
}


resource "aws_api_gateway_deployment" "survey_management_api_deployment" {
  depends_on= [aws_api_gateway_integration.list_all_surveys-post-lambda, aws_api_gateway_integration.add_new_survey-post-lambda,aws_api_gateway_integration.publish_survey-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.survey_management_api.id
  stage_name  = "${var.env}"
}


