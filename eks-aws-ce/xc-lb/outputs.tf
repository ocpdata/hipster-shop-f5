output "load_balancer_name" {
  description = "Nombre del HTTP Load Balancer creado en F5 XC"
  value       = volterra_http_loadbalancer.frontend.name
}

output "origin_pool_name" {
  description = "Nombre del Origin Pool creado en F5 XC"
  value       = volterra_origin_pool.frontend.name
}

output "discovery_name" {
  description = "Nombre del objeto de Service Discovery creado en F5 XC"
  value       = volterra_discovery.eks.name
}

output "app_url" {
  description = "URL pública de la aplicación (apunta al CEL; debes crear el registro DNS en tu proveedor)"
  value       = "http://${var.app_domain}"
}

output "dns_instruction" {
  description = "Instrucción DNS: crea este registro en tu proveedor DNS apuntando al VIP exterior del CE"
  value       = "En tu DNS: ${var.app_domain} IN A <IP-publica-del-CE>"
}

output "console_url" {
  description = "URL directa al Load Balancer en la consola F5 XC"
  value       = "https://${var.f5xc_tenant}.console.ves.volterra.io/web/workspaces/multi-cloud-app-connect/namespaces/${var.f5xc_namespace}/loadbalancers/http/${var.app_name}-lb"
}
