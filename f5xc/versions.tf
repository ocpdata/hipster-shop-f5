terraform {
  required_version = ">= 1.3.0"

  # ─── Terraform Cloud backend ───────────────────────────────────────────────
  # Organización y workspace se configuran mediante env vars:
  #   TF_CLOUD_ORGANIZATION → secret TFC_ORG
  #   TF_WORKSPACE          → var    TFC_WORKSPACE
  cloud {}

  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = ">= 0.11.26"
    }
  }
}

provider "volterra" {
  # Ruta al .p12 y URL pasadas explicitamente via variables de Terraform
  # La contraseña del .p12 se lee desde la env var VES_P12_PASSWORD
  api_p12_file = var.xc_api_p12_file
  url          = var.xc_api_url
}
