output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR de la VPC"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas (para nodos EKS y CE inside)"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDRs de las subnets privadas (para reglas de security group en EKS)"
  value       = aws_subnet.private[*].cidr_block
}

output "outside_subnet_ids" {
  description = "IDs de las subnets outside (para la interfaz exterior del CE)"
  value       = aws_subnet.outside[*].id
}

output "az_names" {
  description = "Lista de AZs usadas"
  value       = var.az_names
}
