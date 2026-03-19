variable "aws_region" {
  description = "Región de AWS donde se desplegará el cluster EKS"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "eks-aws-ce"
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
  description = "ID de la VPC creada en el stack vpc/ (output vpc_id)"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas para los nodos EKS (output private_subnet_ids del stack vpc/)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subnets privadas — usados en el security group de VPC endpoints y regla CE→pods (output private_subnet_cidrs del stack vpc/)"
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

# Los CIDRs del CE inside son los mismos que private_subnet_cidrs
# (el CE se conecta en las mismas subnets privadas que los nodos EKS)

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Project     = "eks-aws-ce"
  }
}
