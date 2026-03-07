# ─── F5 XC ────────────────────────────────────────────────────────────────────
variable "xc_api_p12_file" {
  description = "Ruta al archivo .p12 de la API credential de F5 XC (ej: ./api.p12)"
  type        = string
  default     = "./api.p12"
}

variable "xc_api_url" {
  description = "URL de la API de F5 XC (ej: https://my-company.console.ves.volterra.io/api)"
  type        = string
  sensitive   = true
}

variable "f5xc_tenant" {
  description = "Nombre del tenant en F5 Distributed Cloud (ej: my-company)"
  type        = string
}

variable "f5xc_namespace" {
  description = "Namespace de F5 XC donde se crearán los objetos"
  type        = string
  default     = "system"
}

# ─── Site ─────────────────────────────────────────────────────────────────────
variable "site_name" {
  description = "Nombre del AWS VPC Site en F5 XC"
  type        = string
}

# ─── AWS ──────────────────────────────────────────────────────────────────────
variable "aws_region" {
  description = "Región de AWS donde se desplegará el site"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key ID (usado en F5 XC cloud credentials y en el provider AWS)"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key (usado en F5 XC cloud credentials y en el provider AWS)"
  type        = string
  sensitive   = true
}

variable "aws_credentials_name" {
  description = "Nombre del objeto de credenciales de AWS en F5 XC"
  type        = string
  default     = "aws-site-credentials"
}

# ─── VPC / Networking ─────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR de la VPC que se creará"
  type        = string
  default     = "192.168.0.0/16"
}

variable "master_nodes_az_names" {
  description = "Lista de AZs para los nodos master (1 o 3 para HA)"
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "inside_subnets" {
  description = "CIDRs de las subnets internas (una por AZ)"
  type        = list(string)
  default     = []
}

variable "outside_subnets" {
  description = "CIDRs de las subnets externas (una por AZ)"
  type        = list(string)
  default     = []
}

variable "workload_subnets" {
  description = "CIDRs de las subnets de workload (una por AZ)"
  type        = list(string)
  default     = []
}

# ─── Instance / Access ───────────────────────────────────────────────────────
variable "instance_type" {
  description = "Tipo de instancia EC2 para el nodo CE (ej: t3.xlarge)"
  type        = string
  default     = "t3.xlarge"
}

variable "ssh_key" {
  description = "Clave pública SSH para acceso a los nodos (contenido completo, ej: ssh-rsa AAAA...)"
  type        = string
  sensitive   = true
}

# ─── Labels / Metadata ────────────────────────────────────────────────────────
variable "labels" {
  description = "Tags/labels adicionales que se aplicarán a los recursos"
  type        = map(string)
  default     = {}
}
