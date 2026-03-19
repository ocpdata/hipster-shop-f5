terraform {
  required_version = ">= 1.3.0"

  # Organización y workspace se configuran mediante env vars en CI:
  #   TF_CLOUD_ORGANIZATION → secret TFC_ORG
  #   TF_WORKSPACE          → hardcodeado en el workflow: eks-aws-ce-lb
  cloud {}

  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = ">= 0.11.26"
    }
  }
}

provider "volterra" {
  api_p12_file = var.xc_api_p12_file
  url          = var.xc_api_url
}
