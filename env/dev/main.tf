
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




