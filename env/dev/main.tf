
terraform {
  backend "s3" {
    bucket     = "ta-management-deployment"
    key        = "dev"
    access_key = "AKIA4EXG3DQ2JCNNGCCF"
    secret_key = "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"
    region     = "ap-south-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIA4EXG3DQ2JCNNGCCF"
  secret_key = "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"
}

# module "cognito" {
#   source = "../../cognito/"
# }

# module "aws_rds_instance" {
#     source ="../../rds_db_instance/"
# }

module "authorisation_api" {
  source                = "../../authorisation_apis/"
  env                   = "dev"
  host                  = "vt-survey-database.copaymbev82s.us-east-2.rds.amazonaws.com"
  database              = "vt_survey_management"
  psycopg2_arn          = "arn:aws:lambda:ap-south-1:834781518900:layer:psycopg2_layer_for_python_3_8:1"
  user                  = "postgres"
  password              = "admin123"
  port                  = "5432"
  user_pool_arn         = "arn:aws:cognito-idp:ap-south-1:834781518900:userpool/ap-south-1_cKnp6b0v0"
  client_id             = "41ktatknk96rrk9kjgpe6ighdc"
  group_name_requester  = "requester"
  group_name_respondent = "respondent"
  user_pool_id          = "ap-south-1_cKnp6b0v0"
}

# module "survey_management_apis" {
#   source        = "../../survey_management_apis/"
#   env           = "dev"
#   host          = "vt-survey-database.copaymbev82s.us-east-2.rds.amazonaws.com"
#   database      = "vt_survey_management"
#   psycopg2_arn  = "arn:aws:lambda:us-east-2:124017527459:layer:psycopg2_layer_for_python_3_8:1"
#   user          = "postgres"
#   password      = "admin123"
#   port          = "5432"
#   user_pool_arn = "arn:aws:cognito-idp:us-east-2:124017527459:userpool/us-east-2_QODZHpxZr"
#   user_pool_id  = "us-east-2_QODZHpxZr"
# }

# module "mdm_apis" {
#   source = "../../mdm_apis"
# }

# module "survey_search_apis" {
#   source = "../../survey_search_apis"
# }

# module "survey_metrics_api" {
#   source        = "../../get_survey_metrics/"
#   env           = "dev"
#   host          = "vt-survey-database.copaymbev82s.us-east-2.rds.amazonaws.com"
#   database      = "vt_survey_management"
#   psycopg2_arn  = "arn:aws:lambda:us-east-2:124017527459:layer:psycopg2_layer_for_python_3_8:1"
#   user          = "postgres"
#   password      = "admin123"
#   port          = "5432"
#   user_pool_arn = "arn:aws:cognito-idp:us-east-2:124017527459:userpool/us-east-2_QODZHpxZr"
#   user_pool_id  = "us-east-2_QODZHpxZr"
# }

# module "requester_management_api" {
#   source        = "../../requester_management_api/"
#   env           = "dev"
#   host          = "vt-survey-database.copaymbev82s.us-east-2.rds.amazonaws.com"
#   database      = "vt_survey_management"
#   psycopg2_arn  = "arn:aws:lambda:us-east-2:124017527459:layer:psycopg2_layer_for_python_3_8:1"
#   user          = "postgres"
#   password      = "admin123"
#   port          = "5432"
#   user_pool_arn = "arn:aws:cognito-idp:us-east-2:124017527459:userpool/us-east-2_QODZHpxZr"
#   user_pool_id  = "us-east-2_QODZHpxZr"
# }