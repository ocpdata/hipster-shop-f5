variable "xc_api_url" {
  type    = string
  default = "https://your_xc-cloud_api_url.console.ves.volterra.io/api"
}

variable "xc_api_p12_file" {
  type    = string
  default = "./api-certificate.p12"
}

variable "aws_access_key" {
  type    = string
  default = null
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "aws_region" {
  description = "Región de AWS donde se desplegará el sitio F5 XC."
  type        = string
}

variable "site_name" {
  description = "Nombre del AWS VPC Site en F5 XC."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC existente en AWS donde se desplegará el sitio F5 XC."
  type        = string
}

variable "xc_outside_cidr_blocks" {
  description = "CIDRs para las subnets outside de F5 XC (SLO). No deben colisionar con las subnets EKS."
  type        = list(string)
  default     = ["172.10.61.0/24", "172.10.62.0/24", "172.10.63.0/24"]
}

variable "xc_inside_cidr_blocks" {
  description = "CIDRs para las subnets inside de F5 XC (SLI). No deben colisionar con las subnets EKS."
  type        = list(string)
  default     = ["172.10.11.0/24", "172.10.12.0/24", "172.10.13.0/24"]
}

variable "xc_workload_cidr_blocks" {
  description = "CIDRs para las subnets workload de F5 XC. No deben colisionar con las subnets EKS."
  type        = list(string)
  default     = ["172.10.111.0/24", "172.10.112.0/24", "172.10.113.0/24"]
}
