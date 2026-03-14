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

# ─── F5 XC Tenant / Namespace ─────────────────────────────────────────────────
variable "f5xc_namespace" {
  description = "Namespace de F5 XC donde se crearán los objetos"
  type        = string
  default     = "default"
}

variable "f5xc_tenant" {
  description = "Nombre del tenant en F5 XC (ej: my-company). Usado en URLs de consola."
  type        = string
}

# ─── Site ─────────────────────────────────────────────────────────────────────
variable "site_name" {
  description = "Nombre del AWS VPC Site donde está desplegado el cluster EKS"
  type        = string
}

# ─── App / Load Balancer ──────────────────────────────────────────────────────
variable "app_name" {
  description = "Nombre base para los objetos XC (origin pool, HTTP LB, service discovery)"
  type        = string
  default     = "hipster-shop"
}

variable "app_domain" {
  description = "Dominio público del load balancer (ej: hipster-shop.example.com). Si está vacío usa el dominio auto-generado por F5 XC."
  type        = string
  default     = ""
}

variable "frontend_port" {
  description = "Puerto del servicio frontend en Kubernetes"
  type        = number
  default     = 80
}

variable "k8s_namespace" {
  description = "Namespace de Kubernetes donde está desplegado hipster-shop"
  type        = string
  default     = "default"
}

variable "kubeconfig" {
  description = "Contenido completo del kubeconfig del cluster EKS (obtenido con: aws eks update-kubeconfig --region <region> --name <cluster>)"
  type        = string
  sensitive   = true
}
