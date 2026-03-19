output "site_name" {
  description = "Nombre del AWS VPC Site (CE) creado en F5 XC"
  value       = volterra_aws_vpc_site.ce.name
}

output "site_id" {
  description = "ID único del site en F5 XC"
  value       = volterra_aws_vpc_site.ce.id
}

output "vpc_id" {
  description = "ID de la VPC de AWS utilizada"
  value       = var.vpc_id
}

output "aws_region" {
  description = "Región de AWS donde fue desplegado el CE"
  value       = var.aws_region
}

output "console_url" {
  description = "URL directa al site en la consola de F5 XC"
  value       = "https://${var.f5xc_tenant}.console.ves.volterra.io/web/workspaces/multi-cloud-network-connect/sites/aws-vpc-sites/${volterra_aws_vpc_site.ce.name}"
}
