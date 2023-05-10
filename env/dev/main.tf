
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
  host                  = "spe-major-project.cqfn3y5ohgqj.ap-south-1.rds.amazonaws.com"
  database              = "spe_major"
  psycopg2_arn          = "arn:aws:lambda:ap-south-1:834781518900:layer:psycopg2_layer_for_python_3_8:1"
  user                  = "postgres"
  password              = "admin123"
  port                  = "5432"
  user_pool_arn         = "arn:aws:cognito-idp:ap-south-1:834781518900:userpool/ap-south-1_cKnp6b0v0"
  client_id             = "41ktatknk96rrk9kjgpe6ighdc"
  group_name_student  = "student"
  group_name_professor = "professor"
  user_pool_id          = "ap-south-1_cKnp6b0v0"
}

module "is_user_registered" {
  source                = "../../is_user_registered/"
  env                   = "dev"
  host                  = "spe-major-project.cqfn3y5ohgqj.ap-south-1.rds.amazonaws.com"
  database              = "spe_major"
  psycopg2_arn          = "arn:aws:lambda:ap-south-1:834781518900:layer:psycopg2_layer_for_python_3_8:1"
  user                  = "postgres"
  password              = "admin123"
  port                  = "5432"
  user_pool_arn         = "arn:aws:cognito-idp:ap-south-1:834781518900:userpool/ap-south-1_cKnp6b0v0"
  user_pool_id          = "ap-south-1_cKnp6b0v0"
}

module "user_management_api" {
  source                = "../../user_management_api/"
  env                   = "dev"
  host                  = "spe-major-project.cqfn3y5ohgqj.ap-south-1.rds.amazonaws.com"
  database              = "spe_major"
  psycopg2_arn          = "arn:aws:lambda:ap-south-1:834781518900:layer:psycopg2_layer_for_python_3_8:1"
  user                  = "postgres"
  password              = "admin123"
  port                  = "5432"
  user_pool_arn         = "arn:aws:cognito-idp:ap-south-1:834781518900:userpool/ap-south-1_cKnp6b0v0"
  user_pool_id          = "ap-south-1_cKnp6b0v0"
}

module "ta_vacancy_apis" {
  source                = "../../ta_vacancy_apis/"
  env                   = "dev"
  host                  = "spe-major-project.cqfn3y5ohgqj.ap-south-1.rds.amazonaws.com"
  database              = "spe_major"
  psycopg2_arn          = "arn:aws:lambda:ap-south-1:834781518900:layer:psycopg2_layer_for_python_3_8:1"
  user                  = "postgres"
  password              = "admin123"
  port                  = "5432"
  user_pool_arn         = "arn:aws:cognito-idp:ap-south-1:834781518900:userpool/ap-south-1_cKnp6b0v0"
  user_pool_id          = "ap-south-1_cKnp6b0v0"
}

# module "add_kubernetes_lambda" {
#   source                = "../../add_kubernetes_lambda/"
#   env                   = "dev"
#   host                  = "spe-major-project.cqfn3y5ohgqj.ap-south-1.rds.amazonaws.com"
#   database              = "spe_major"
#   psycopg2_arn          = "arn:aws:lambda:ap-south-1:834781518900:layer:psycopg2_layer_for_python_3_8:1"
#   user                  = "postgres"
#   password              = "admin123"
#   port                  = "5432"
#   user_pool_arn         = "arn:aws:cognito-idp:ap-south-1:834781518900:userpool/ap-south-1_cKnp6b0v0"
#   user_pool_id          = "ap-south-1_cKnp6b0v0"
# }