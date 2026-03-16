variable "aws_region" {
  description = "Región de AWS donde se desplegará el cluster EKS"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "eks-3sn"
}

variable "cluster_version" {
  description = "Versión de Kubernetes para el cluster EKS"
  type        = string
  default     = "1.29"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "ID de la VPC existente en AWS"
  type        = string
}

variable "private_subnet_ids" {
  description = "Lista de 3 IDs de subnets privadas existentes (una por AZ)"
  type        = list(string)
}

variable "node_instance_types" {
  description = "Tipos de instancia para los nodos del cluster"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Número máximo de nodos"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Número deseado de nodos"
  type        = number
  default     = 2
}

variable "xc_inside_cidr_blocks" {
  description = "CIDRs de las subnets inside del CE de F5 XC"
  type        = list(string)
  default     = ["172.10.11.0/24", "172.10.12.0/24", "172.10.13.0/24"]
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Project     = "eks-3sn"
  }
}
