variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC (ej: 10.0.0.0/16). Las subnets se derivan automáticamente con cidrsubnet()."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_names" {
  description = "Lista de AZs donde se crearán subnets (ej: [\"us-east-1a\",\"us-east-1b\"]). Una subnet privada y una outside por AZ."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  description = "Tags aplicados a todos los recursos de red"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "eks-aws-ce"
  }
}
