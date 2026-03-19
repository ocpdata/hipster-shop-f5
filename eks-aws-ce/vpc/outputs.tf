output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR de la VPC"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas para nodos EKS (con ruta NAT)"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDRs de las subnets privadas (para reglas de security group en EKS)"
  value       = aws_subnet.private[*].cidr_block
}

output "ce_inside_subnet_ids" {
  description = "IDs del subnet CE inside (sin route table — F5 XC gestiona el routing)"
  value       = [aws_subnet.ce_inside.id]
}

output "ce_outside_subnet_ids" {
  description = "IDs del subnet CE outside (sin route table — F5 XC gestiona el routing + IGW)"
  value       = [aws_subnet.ce_outside.id]
}

output "az_names" {
  description = "Lista de AZs usadas"
  value       = var.az_names
}
