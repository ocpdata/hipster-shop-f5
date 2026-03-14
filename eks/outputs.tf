output "aws_region" {
  description = "Región de AWS del cluster EKS"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del API server del cluster EKS"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Certificate Authority del cluster EKS (base64)"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "Versión de Kubernetes del cluster"
  value       = module.eks.cluster_version
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.vpc.vpc_id
}

output "outside_subnets" {
  description = "IDs de las subnets externas (outside)"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "IDs de las subnets privadas"
  value       = module.vpc.private_subnets
}

output "workload_subnets" {
  description = "IDs de las subnets de workload"
  value       = module.vpc.intra_subnets
}

output "configure_kubectl" {
  description = "Comando para configurar kubectl y conectarse al cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
