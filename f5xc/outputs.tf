output "site_name" {
  description = "Nombre del AWS VPC Site creado en F5 XC"
  value       = module.aws_vpc_site.site_name
}

output "site_id" {
  description = "ID único del site en F5 XC"
  value       = module.aws_vpc_site.site_id
}

output "vpc_id" {
  description = "ID de la VPC de AWS creada para el site"
  value       = module.aws_vpc_site.vpc_id
}

output "aws_region" {
  description = "Región de AWS donde fue desplegado el site"
  value       = var.aws_region
}

output "console_url" {
  description = "URL directa al site en la consola de F5 XC"
  value       = "https://${var.f5xc_tenant}.console.ves.volterra.io/web/workspaces/multi-cloud-network-connect/sites/aws-vpc-sites/${module.aws_vpc_site.site_name}"
}
