variable "aws_region" {
  description = "Región de AWS donde se desplegará el cluster EKS"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "eks-cluster"
}

variable "cluster_version" {
  description = "Versión de Kubernetes para el cluster EKS"
  type        = string
  default     = "1.29"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = ""
}

variable "outside_subnets" {
  description = "Lista de CIDRs para subnets externas (acceso a internet vía IGW)"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "Lista de CIDRs para subnets privadas (acceso a internet vía NAT)"
  type        = list(string)
  default     = []
}

variable "workload_subnets" {
  description = "Lista de CIDRs para subnets de workload (sin acceso a internet)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------
# Subnets dedicadas para F5 XC (sin route tables)
# F5 XC gestiona sus propias route tables en estas subnets.
# Deben ser ranges libres dentro del VPC CIDR que no colisionen con las subnets EKS.
# -----------------------------------------------
variable "xc_outside_subnets" {
  description = "CIDRs para subnets outside de F5 XC (SLO). Sin route table previa."
  type        = list(string)
  default     = ["172.10.61.0/24", "172.10.62.0/24", "172.10.63.0/24"]
}

variable "xc_inside_subnets" {
  description = "CIDRs para subnets inside de F5 XC (SLI). Sin route table previa."
  type        = list(string)
  default     = ["172.10.11.0/24", "172.10.12.0/24", "172.10.13.0/24"]
}

variable "xc_workload_subnets" {
  description = "CIDRs para subnets workload de F5 XC. Sin route table previa."
  type        = list(string)
  default     = ["172.10.111.0/24", "172.10.112.0/24", "172.10.113.0/24"]
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

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Project     = "eks-cluster"
  }
}
