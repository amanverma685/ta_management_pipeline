//-------------------- API Gateway --------------------

resource "aws_api_gateway_rest_api" "master_data" {
  name        = "Master Data"
  description = "API to get master data"
}

//-------------------- Departments --------------------


resource "aws_api_gateway_resource" "departments" {
  rest_api_id = aws_api_gateway_rest_api.master_data.id
  parent_id   = aws_api_gateway_rest_api.master_data.root_resource_id
  path_part   = "departments"
}

resource "aws_api_gateway_method" "departments_GET" {
  rest_api_id   = aws_api_gateway_rest_api.master_data.id
  resource_id   = aws_api_gateway_resource.departments.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "department_lambda" {
  rest_api_id = aws_api_gateway_rest_api.master_data.id
  resource_id = aws_api_gateway_method.departments_GET.resource_id
  http_method = aws_api_gateway_method.departments_GET.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.departments.invoke_arn
}

module "cors_departments" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.master_data.id
  api_resource_id = aws_api_gateway_resource.departments.id
}


//-------------------- Specialization --------------------


resource "aws_api_gateway_resource" "specialization" {
  rest_api_id = aws_api_gateway_rest_api.master_data.id
  parent_id   = aws_api_gateway_rest_api.master_data.root_resource_id
  path_part   = "specialization"
}

resource "aws_api_gateway_method" "specialization_GET" {
  rest_api_id   = aws_api_gateway_rest_api.master_data.id
  resource_id   = aws_api_gateway_resource.specialization.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "specialization_lambda" {
  rest_api_id = aws_api_gateway_rest_api.master_data.id
  resource_id = aws_api_gateway_method.specialization_GET.resource_id
  http_method = aws_api_gateway_method.specialization_GET.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.specialization.invoke_arn
}

// -------------------- Deployment --------------------

resource "aws_api_gateway_deployment" "master_data" {
  depends_on = [
    aws_api_gateway_integration.department_lambda,
    aws_api_gateway_integration.specialization_lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.master_data.id
  stage_name  = "test"
}

// -------------------- CORS -----------------------

module "cors_specialization" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.master_data.id
  api_resource_id = aws_api_gateway_resource.specialization.id
}
