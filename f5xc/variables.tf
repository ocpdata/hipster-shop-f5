# ─── Terraform Cloud ──────────────────────────────────────────────────────────
variable "tfc_organization" {
  description = "Nombre de la organización en Terraform Cloud"
  type        = string
}

variable "tfc_workspace" {
  description = "Nombre del workspace en Terraform Cloud"
  type        = string
  default     = "f5xc-aws-site"
}

# ─── F5 XC ────────────────────────────────────────────────────────────────────
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

variable "site_description" {
  description = "Descripción del site"
  type        = string
  default     = ""
}

# ─── AWS ──────────────────────────────────────────────────────────────────────
variable "aws_region" {
  description = "Región de AWS donde se desplegará el site"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key ID para las credenciales cloud en F5 XC"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key para las credenciales cloud en F5 XC"
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
  description = "CIDR de la VPC que se creará (dejar vacío para autogenerar)"
  type        = string
  default     = "192.168.0.0/16"
}

variable "az_names" {
  description = "Lista de AZs a usar (mínimo 1, hasta 3 para HA). Las subnets se generan automáticamente con cidrsubnet: AZ[0]=.1.0/24, AZ[1]=.2.0/24, AZ[2]=.3.0/24"
  type        = list(string)
  default     = ["us-east-1a"]
}

# subnet_cidr eliminado: cada AZ recibe su propio /24 automáticamente
# usando cidrsubnet(vpc_cidr, 8, index + 1) en main.tf

# ─── Node type ────────────────────────────────────────────────────────────────
variable "certified_hw" {
  description = "Hardware certificado F5 XC para el nodo CE en AWS (var: AWS_XC_HW_PROFILE)"
  type        = string
  default     = "aws-byol-multi-nic-voltmesh"
  # Otros valores posibles:
  #   aws-byol-single-nic-voltmesh
  #   aws-byol-voltstack-combo
}

# ─── Labels / Metadata ────────────────────────────────────────────────────────
variable "labels" {
  description = "Labels adicionales que se aplicarán al site"
  type        = map(string)
  default     = {}
}
