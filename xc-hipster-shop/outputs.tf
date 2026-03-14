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
  description = "URL para acceder a hipster-shop (dominio custom o auto-generado por F5 XC)"
  value       = local.use_custom_domain ? "http://${var.app_domain}" : "Ver en F5 XC Console → HTTP Load Balancers → ${var.app_name}-lb → Domain"
}

output "console_url" {
  description = "URL directa al Load Balancer en la consola F5 XC"
  value       = "https://${var.f5xc_tenant}.console.ves.volterra.io/web/workspaces/multi-cloud-app-connect/namespaces/${var.f5xc_namespace}/loadbalancers/http/${var.app_name}-lb"
}
