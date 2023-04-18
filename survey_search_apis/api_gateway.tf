//-------------------- API Gateway --------------------

resource "aws_api_gateway_rest_api" "search" {
  name        = "Survey Search"
  description = "API to search and fiter surveys"
}

//-------------------- Departments --------------------


resource "aws_api_gateway_resource" "filter" {
  rest_api_id = aws_api_gateway_rest_api.search.id
  parent_id   = aws_api_gateway_rest_api.search.root_resource_id
  path_part   = "filter"
}

resource "aws_api_gateway_method" "search_POST" {
  rest_api_id   = aws_api_gateway_rest_api.search.id
  resource_id   = aws_api_gateway_resource.filter.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "search_lambda" {
  rest_api_id = aws_api_gateway_rest_api.search.id
  resource_id = aws_api_gateway_method.search_POST.resource_id
  http_method = aws_api_gateway_method.search_POST.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.filter.invoke_arn
}

module "cors_filter" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.search.id
  api_resource_id = aws_api_gateway_resource.filter.id
}

// -------------------- Deployment --------------------

resource "aws_api_gateway_deployment" "search" {
  depends_on = [
    aws_api_gateway_integration.search_lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.search.id
  stage_name  = "test"
}
