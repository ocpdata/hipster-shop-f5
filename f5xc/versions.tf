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
  # Configuración inyectada vía variables de entorno en CI/CD:
  #   VOLT_API_P12_FILE  → ruta al .p12 exportado de F5 XC Console
  #   VOLT_API_URL       → https://<tenant>.console.ves.volterra.io/api  (secret XC_API_URL)
  #   VES_P12_PASSWORD   → contraseña del .p12 decodificada de base64    (secret XC_P12_PASSWORD)
  #
  # Para ejecución local, exporta esas variables antes de correr terraform.
}
