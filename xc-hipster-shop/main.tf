locals {
  # Si app_domain está vacío, F5 XC generará un dominio automático
  use_custom_domain = var.app_domain != ""
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. Service Discovery — descubre los servicios Kubernetes del cluster EKS
#    usando el kubeconfig del cluster (pasado como variable sensible).
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_discovery" "eks" {
  name      = "${var.app_name}-discovery"
  namespace = var.f5xc_namespace

  discovery_k8s {
    access_info {
      kubeconfig_url {
        clear_secret_info {
          url = "string:///${base64encode(var.kubeconfig)}"
        }
      }
    }
    publish_info {
      publish {
        namespace = var.f5xc_namespace
      }
    }
  }

  where {
    site {
      ref {
        name      = var.site_name
        namespace = "system"
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

  # Dominio: custom o wildcard (acepta cualquier host header)
  domains = local.use_custom_domain ? [var.app_domain] : ["*"]

  # Advertise en internet usando el VIP público por defecto de F5 XC
  advertise_on_public_default_vip = true

  # Routing: todo el tráfico va al origin pool del frontend
  default_route_pools {
    pool {
      name      = volterra_origin_pool.frontend.name
      namespace = var.f5xc_namespace
    }
    weight   = 1
    priority = 1
  }

  # HTTP (sin TLS por ahora — añadir certificado para HTTPS)
  http {
    dns_volterra_managed = false
    port                 = "80"
  }

  # Deshabilitar WAF y políticas adicionales (se pueden activar después)
  disable_waf         = true
  no_challenge        = true
  disable_rate_limit  = true
  no_service_policies = true
  add_location        = true

  depends_on = [volterra_origin_pool.frontend]
}
