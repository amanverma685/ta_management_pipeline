terraform {
  backend "s3" {
    bucket = "terraform-deployement-state"
    key = "test"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "us-east-1   "
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
  region = "us-east-1"
}

