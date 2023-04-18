resource "null_resource" "health_check" {
  provisioner "local-exec" {
    command = "cd ../../survey_search_apis/filter; npm i pg"
  }
}

data "archive_file" "filter" {
  type        = "zip"
  source_dir  = "../../survey_search_apis/filter/"
  output_path = "../../survey_search_apis/filter/filter.zip"
  depends_on = [
    null_resource.health_check
  ]
}

resource "aws_lambda_function" "filter" {
  function_name    = "get-filtered-surveys"
  filename         = "../../survey_search_apis/filter/filter.zip"
  source_code_hash = data.archive_file.filter.output_base64sha256

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "nodejs18.x"

  role = aws_iam_role.aws_iam_role_filtered_surveys.arn
}

resource "aws_iam_policy" "aws_iam_role_filtered_surveys" {
  name = "get-filtered-surveys-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "aws_iam_role_filtered_surveys" {
  name = "aws_iam_role_filtered_surveys"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test_attach_publish_survey" {
  role       = aws_iam_role.aws_iam_role_filtered_surveys.name
  policy_arn = aws_iam_policy.aws_iam_role_filtered_surveys.arn
}

resource "aws_lambda_permission" "aws_lambda_filtered_surveys_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.filter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.search.execution_arn}/*/*"
}
