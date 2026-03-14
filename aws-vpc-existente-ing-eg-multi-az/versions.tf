terraform {
  required_version = ">= 1.0"

  # ─── Terraform Cloud backend ───────────────────────────────────────────────
  # Organización y workspace se configuran mediante env vars:
  #   TF_CLOUD_ORGANIZATION → secret TFC_ORG
  #   TF_WORKSPACE          → var    TFC_WORKSPACE_EXISTENTE
  cloud {}

  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.44"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.9.0"
    }
  }
}
