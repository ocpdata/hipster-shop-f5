terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Organización y workspace se configuran mediante env vars en CI:
  #   TF_CLOUD_ORGANIZATION → secret TFC_ORG
  #   TF_WORKSPACE          → hardcodeado en el workflow: eks-aws-ce
  cloud {}
}

provider "aws" {
  region = var.aws_region
}
