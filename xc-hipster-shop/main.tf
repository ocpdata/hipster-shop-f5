locals {
  # Si app_domain está vacío, F5 XC generará un dominio automático
  use_custom_domain = var.app_domain != ""
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. Service Discovery — descubre los servicios Kubernetes del cluster EKS
#    vía el nodo F5 XC desplegado en la VPC (sin kubeconfig externo).
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_discovery" "eks" {
  name      = "${var.app_name}-discovery"
  namespace = var.f5xc_namespace

  # Descubrimiento vía XC site (el nodo CE accede al API server de EKS
  # desde dentro de la VPC usando la ruta local)
  discovery_k8s {
    access_info {
      connection_info {
        api_server = "https://kubernetes.default.svc"
        tls_info {
          insecure_skip_verify = true
        }
      }
      in_cluster = true
    }
    publish_info {
      publish = true
    }
  }

  where {
    site {
      ref {
        name      = var.site_name
        namespace = "system"
        tenant    = var.f5xc_tenant
      }
      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. Origin Pool — apunta al servicio frontend descubierto vía service discovery
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_origin_pool" "frontend" {
  name      = "${var.app_name}-frontend"
  namespace = var.f5xc_namespace

  origin_servers {
    k8s_service {
      service_name = "frontend.${var.k8s_namespace}"
      site_locator {
        site {
          name      = var.site_name
          namespace = "system"
          tenant    = var.f5xc_tenant
        }
      }
      inside_network = true
    }
  }

  port                 = var.frontend_port
  no_tls               = true
  endpoint_selection   = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE_NONE"

  depends_on = [volterra_discovery.eks]
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. HTTP Load Balancer — expone el frontend en internet a través de F5 XC
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_http_loadbalancer" "frontend" {
  name      = "${var.app_name}-lb"
  namespace = var.f5xc_namespace

  # Dominio: custom o auto-generado por F5 XC
  domains = local.use_custom_domain ? [var.app_domain] : []

  # Advertise en internet desde el site AWS
  advertise_custom {
    advertise_where {
      port = 80
      site {
        ip          = "DEFAULT_INTERFACE_IP"
        network     = "SITE_NETWORK_OUTSIDE"
        site {
          name      = var.site_name
          namespace = "system"
          tenant    = var.f5xc_tenant
        }
      }
    }
  }

  # Routing: todo el tráfico va al origin pool del frontend
  default_route_pools {
    pool {
      name      = volterra_origin_pool.frontend.name
      namespace = var.f5xc_namespace
      tenant    = var.f5xc_tenant
    }
    weight   = 1
    priority = 1
  }

  # HTTP (sin TLS por ahora — añadir certifcado para HTTPS)
  no_tls = true

  # Deshabilitar WAF y políticas adicionales (se pueden activar después)
  disable_waf                     = true
  no_challenge                    = true
  disable_rate_limit              = true
  no_service_policies             = true
  no_ip_reputation                = true
  multi_lb_app                    = false
  user_id_client_ip               = true
  source_ip_stickiness            = false
  add_location                    = true

  depends_on = [volterra_origin_pool.frontend]
}
