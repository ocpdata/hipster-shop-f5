# ─── F5 XC API ────────────────────────────────────────────────────────────────
variable "xc_api_p12_file" {
  description = "Ruta al archivo .p12 de la API credential de F5 XC"
  type        = string
  default     = "./api.p12"
}

variable "xc_api_url" {
  description = "URL de la API de F5 XC (ej: https://my-tenant.console.ves.volterra.io/api)"
  type        = string
  sensitive   = true
}

variable "f5xc_tenant" {
  description = "Nombre del tenant en F5 XC (ej: my-company). Usado en URLs de consola."
  type        = string
}

# ─── Site ─────────────────────────────────────────────────────────────────────
variable "site_name" {
  description = "Nombre del AWS VPC Site (CE) en F5 XC"
  type        = string
  default     = "eks-aws-ce-site"
}

# ─── AWS ──────────────────────────────────────────────────────────────────────
variable "aws_region" {
  description = "Región de AWS donde se desplegará el CE"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "aws_credentials_name" {
  description = "Nombre del objeto de credenciales de AWS en F5 XC"
  type        = string
  default     = "aws-ce-credentials"
}

# ─── VPC / Networking ─────────────────────────────────────────────────────────
variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el CE (output vpc_id del stack vpc/)"
  type        = string
}

variable "az_names" {
  description = "Lista de AZs donde se instalarán los nodos CE. F5 XC acepta exactamente 1 o 3 AZs."
  type        = list(string)
  default     = ["us-east-1a"]

  validation {
    condition     = length(var.az_names) == 1 || length(var.az_names) == 3
    error_message = "F5 XC solo acepta 1 o 3 az_nodes para ingress_egress_gw. Recibido: ${length(var.az_names)}."
  }
}

variable "outside_subnet_ids" {
  description = "IDs de las subnets outside para la interfaz exterior del CE. Debe tener el mismo número de elementos que az_names (1 o 3)."
  type        = list(string)
}

variable "inside_subnet_ids" {
  description = "IDs de las subnets inside del CE — mismas subnets privadas que los nodos EKS. Debe tener el mismo número de elementos que az_names (1 o 3)."
  type        = list(string)
}

# ─── CE Instance ─────────────────────────────────────────────────────────────
variable "ce_instance_type" {
  description = "Tipo de instancia EC2 para el nodo CE"
  type        = string
  default     = "t3.xlarge"
}

variable "ssh_key" {
  description = "Clave pública SSH para acceso a los nodos CE (contenido full, ej: ssh-rsa AAAA...)"
  type        = string
  sensitive   = true
}

variable "site_validation_wait" {
  description = "Tiempo de espera tras crear el AWS VPC Site para que F5 XC complete la validación interna antes del apply. Aumentar si el apply falla con 'config validation did not succeed'."
  type        = string
  default     = "300s"
}

# ─── Labels ───────────────────────────────────────────────────────────────────
variable "labels" {
  description = "Labels aplicados al site en F5 XC"
  type        = map(string)
  default = {
    env     = "dev"
    project = "eks-aws-ce"
  }
}
