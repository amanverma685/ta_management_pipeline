resource "aws_cognito_user_pool" "pool" {
  name = "vt-university-survey"
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "first_name"
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "last_name"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "dob"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "country"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "department_name"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "university_name"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "research_area"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "mobile_no"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "user_group"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "middle_name"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                     = "user_id"
    attribute_data_type      = "String"
    mutable                  = true
    developer_only_attribute = false
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "client"

  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret     = false
  explicit_auth_flows = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "vt-university-survey"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client.id
    provider_name           = aws_cognito_user_pool.pool.endpoint
    server_side_token_check = false
  }
}


resource "aws_iam_role" "auth_iam_role" {
  name               = "auth_iam_role"
  assume_role_policy = <<EOF
 {
      "Version": "2012-10-17",
      "Statement": [
           {
                "Action": "sts:AssumeRole",
                "Principal": {
                     "Federated": "cognito-identity.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
           }
      ]
 }
 EOF
}

resource "aws_iam_role" "unauth_iam_role" {
  name = "unauth_iam_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Federated" : "cognito-identity.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "web_iam_unauth_role_policy" {
  name = "web_iam_unauth_role_policy"
  role = aws_iam_role.unauth_iam_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Action" : "*",
        "Effect" : "Deny",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    authenticated   = aws_iam_role.auth_iam_role.arn
    unauthenticated = aws_iam_role.unauth_iam_role.arn
  }
}

data "aws_iam_policy_document" "group_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = ["us-east-1:12345678-dead-beef-cafe-123456790ab"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

resource "aws_iam_role" "vt_survey_cognito_group_role" {
  name               = "vt-survey-cognito-group"
  assume_role_policy = data.aws_iam_policy_document.group_role.json
}

resource "aws_cognito_user_group" "vt_survey_admin_group" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.pool.id
  precedence   = 1
  role_arn     = aws_iam_role.vt_survey_cognito_group_role.arn
}

resource "aws_cognito_user_group" "vt_survey_requester_group" {
  name         = "requester"
  user_pool_id = aws_cognito_user_pool.pool.id
  precedence   = 2
  role_arn     = aws_iam_role.vt_survey_cognito_group_role.arn
}

resource "aws_cognito_user_group" "vt_survey_respondent_group" {
  name         = "respondent"
  user_pool_id = aws_cognito_user_pool.pool.id
  precedence   = 3
  role_arn     = aws_iam_role.vt_survey_cognito_group_role.arn
}
