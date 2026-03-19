output "aws_region" {
  description = "Región de AWS del cluster EKS"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del API server del cluster EKS (privado)"
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
  description = "ID de la VPC utilizada"
  value       = var.vpc_id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas donde corren los nodos EKS (usadas como inside del CE)"
  value       = var.private_subnet_ids
}

output "node_security_group_id" {
  description = "ID del security group de los nodos EKS"
  value       = module.eks.node_security_group_id
}

output "configure_kubectl" {
  description = "Comando para configurar kubectl (ejecutar desde la misma VPC o VPN)"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
