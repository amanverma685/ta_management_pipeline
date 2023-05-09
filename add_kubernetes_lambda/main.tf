resource "aws_iam_role" "iam_container_test" {
  name = "iam_container_test_${var.env}"

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


resource "aws_iam_policy" "container_test_policy" {
  name        = "container_test_policy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "test_attach_container_test" {
  role       = aws_iam_role.iam_container_test.name
  policy_arn = aws_iam_policy.container_test_policy.arn
}


resource "aws_lambda_function" "container_test" {


  filename      = "../../add_kubernetes_lambda/container_test.zip"
  function_name = "container_test"
  role          = aws_iam_role.iam_container_test.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("../../add_kubernetes_lambda/container_test.zip")

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

resource "aws_lambda_permission" "aws_lambda_container_test_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.container_test.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.container_test.execution_arn}/*/*"
}

# API Name
resource "aws_api_gateway_rest_api" "container_test" {
  name = "Test ECS"
  description = "Api to get user details"
}

# Authorizer
resource "aws_api_gateway_authorizer" "container_test" {
  name = "container_test_authorizer"
  rest_api_id = aws_api_gateway_rest_api.container_test.id
  type = "COGNITO_USER_POOLS"
  provider_arns = ["${var.user_pool_arn}"]
}

# root resource container_test
resource "aws_api_gateway_resource" "container_test" {
  rest_api_id = aws_api_gateway_rest_api.container_test.id
  parent_id = aws_api_gateway_rest_api.container_test.root_resource_id
  path_part = "container_test"
}

# child resource : container_test
resource "aws_api_gateway_resource" "container_test" {
  rest_api_id = aws_api_gateway_rest_api.container_test.id
  parent_id = aws_api_gateway_resource.container_test.id
  path_part = "{user_id}"
}


# container_test : method
resource "aws_api_gateway_method" "POST_container_test" {
  rest_api_id = aws_api_gateway_rest_api.container_test.id
  resource_id = aws_api_gateway_resource.container_test.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.container_test.id
}

#  lambda integration : container_test-post-lambda
resource "aws_api_gateway_integration" "container_test-post-lambda" {
  rest_api_id = aws_api_gateway_rest_api.container_test.id
  resource_id = aws_api_gateway_method.POST_container_test.resource_id
  http_method = aws_api_gateway_method.POST_container_test.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_ecs_service.my_service.load_balancer.first_dns_name

  request_templates = {
    "application/json" = <<EOF
    {
      "containerOverrides": [
        {
          "name": "my-container",
          "command": [
            "my-command"
          ]
        }
      ],
      "taskDefinition": "${aws_ecs_task_definition.my_task.family}:${max("${aws_ecs_task_definition.my_task.revision}", "${data.aws_ecs_task_definition.my_task.revision}")}",
      "launchType": "FARGATE",
      "networkConfiguration": {
        "awsvpcConfiguration": {
          "subnets": [
            "subnet-12345678"
          ],
          "securityGroups": [
            "sg-12345678"
          ],
          "assignPublicIp": "DISABLED"
        }
      }
    }
EOF
  }

  depends_on = [
    aws_ecs_service.my_service
  ]


}

module "cors_container_test" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  api_id          = aws_api_gateway_rest_api.container_test.id
  api_resource_id = aws_api_gateway_resource.container_test.id
}


resource "aws_api_gateway_deployment" "container_test_deployment" {
  depends_on= [aws_api_gateway_integration.container_test-post-lambda]
  rest_api_id = aws_api_gateway_rest_api.container_test.id
  stage_name  = "${var.env}"
}

# Create an ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  container_definitions    = <<DEFINITION
[
  {
    "name": "my-container",
    "image": "my-image:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
}

# Create an ECS service
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 1

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets         = ["subnet-12345678"]
    security_groups = ["sg-12345678"]
  }
}

