resource "aws_iam_role" "iam_test_kubernetes" {
  name = "iam_test_kubernetes_${var.env}"

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


resource "aws_iam_policy" "test_kubernetes_policy" {
  name        = "test_kubernetes_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_test_kubernetes" {
  role       = aws_iam_role.iam_test_kubernetes.name
  policy_arn = aws_iam_policy.test_kubernetes_policy.arn
}


resource "aws_lambda_function" "test_kubernetes" {


  filename      = "../../add_kubernetes_lambda/test_kubernetes.zip"
  function_name = "test_kubernetes"
  role          = aws_iam_role.iam_test_kubernetes.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../add_kubernetes_lambda/test_kubernetes.zip")

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

resource "aws_lambda_permission" "aws_lambda_test_kubernetes_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_kubernetes.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.kubernetes_test.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "kubernetes_test" {
  name = "Test Kubernetes"
  description = "Api to get user details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "kubernetes_test" {
  name = "kubernetes_test_authorizer"
  rest_api_id = aws_api_gateway_rest_api.kubernetes_test.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource kubernetes_test
resource "aws_api_gateway_resource" "kubernetes_test" {
  rest_api_id = aws_api_gateway_rest_api.kubernetes_test.id
  parent_id = aws_api_gateway_rest_api.kubernetes_test.root_resource_id
  path_part = "kubernetes_test"
}

# child resource : test_kubernetes
resource "aws_api_gateway_resource" "test_kubernetes" {
  rest_api_id = aws_api_gateway_rest_api.kubernetes_test.id
  parent_id = aws_api_gateway_resource.kubernetes_test.id
  path_part = "{user_id}"
}


# test_kubernetes : method
resource "aws_api_gateway_method" "POST_test_kubernetes" {
  rest_api_id = aws_api_gateway_rest_api.kubernetes_test.id
  resource_id = aws_api_gateway_resource.test_kubernetes.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.kubernetes_test.id
}

#  lambda integration : test_kubernetes-post-lambda
resource "aws_api_gateway_integration" "test_kubernetes-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.kubernetes_test.id
  resource_id = aws_api_gateway_method.POST_test_kubernetes.resource_id
  http_method = aws_api_gateway_method.POST_test_kubernetes.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.test_kubernetes.invoke_arn
}

module "cors_test_kubernetes" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.kubernetes_test.id
  api_resource_id = aws_api_gateway_resource.test_kubernetes.id
}


resource "aws_api_gateway_deployment" "kubernetes_test_deployment" {
  depends_on= [aws_api_gateway_integration.test_kubernetes-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.kubernetes_test.id
  stage_name  = "${var.env}"
}

# Create a Kubernetes deployment for the Lambda function
resource "kubernetes_deployment" "example_lambda" {
  metadata {
    name = "example-lambda"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "example-lambda"
      }
    }

    template {
      metadata {
        labels = {
          app = "example-lambda"
        }
      }

      spec {
        container {
          image = aws_lambda_function.test_kubernetes.invoke_arn
          name  = "example-lambda"
        }
      }
    }
  }
}

# Create a Kubernetes service for the Lambda function
resource "kubernetes_service" "example_lambda" {
  metadata {
    name = "example-lambda"
  }

  spec {
    selector = {
      app = "example-lambda"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}


resource "kubernetes_ingress" "example_api" {
  metadata {
    name = "example-api"
  }

  spec {
    backend {
      service_name = kubernetes_service.example_lambda.metadata[0].name
      service_port = kubernetes_service.example_lambda.spec[0].port[0].port
    }

    rule {
      http {
        path {
          backend {
            service_name = kubernetes_service.example_lambda.metadata[0].name
            service_port = kubernetes_service.example_lambda.spec[0].port[0].port
          }

          path = "/example"
        }
      }
    }
  }
}
