terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # TF_CLOUD_ORGANIZATION y TF_WORKSPACE se pasan como env vars en CI
  cloud {}
}

provider "aws" {
  region = var.aws_region
}
