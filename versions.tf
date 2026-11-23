terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.25"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

provider "awscc" {
  region = var.region
}
