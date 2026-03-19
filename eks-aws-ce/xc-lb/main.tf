# ─────────────────────────────────────────────────────────────────────────────
# 1. Service Discovery — descubre los servicios de Kubernetes en el cluster EKS
#    El CE (Customer Edge) actúa como proxy entre F5 XC y el API Server de EKS.
#    Se usa la red inside del CE para alcanzar el API Server privado.
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

  # El CE ve los pods/servicios a través de su interfaz inside (misma VPC que EKS)
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
# 2. Origin Pool — apunta al servicio frontend (ClusterIP) de EKS
#    F5 XC resuelve el nombre K8s via Service Discovery y usa el CE para alcanzarlo.
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
      # Usar la red inside del CE para alcanzar el ClusterIP de EKS
      inside_network = true
    }
  }

  port                   = var.frontend_port
  no_tls                 = true
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE_NONE"

  depends_on = [volterra_discovery.eks]
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. HTTP Load Balancer — expone la app en internet a través del CE
#    El dominio casos.accessq.com es gestionado por tu propio DNS (Route53/CF/etc).
#    Debes crear un registro A apuntando al VIP público del CE.
#    NO se usa dns_volterra_managed ya que el dominio no está delegado a F5 XC.
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_http_loadbalancer" "frontend" {
  name      = "${var.app_name}-lb"
  namespace = var.f5xc_namespace

  # Dominio de la aplicación — gestionado en tu propio DNS
  domains = [var.app_domain]

  # Publicar en el CE específico (no en el VIP compartido de F5 XC)
  advertise_custom {
    advertise_where {
      site {
        site {
          name      = var.site_name
          namespace = "system"
        }
        network = "SITE_NETWORK_OUTSIDE"
      }
      port = 80
    }
  }

  # Routing hacia el origin pool del frontend
  default_route_pools {
    pool {
      name      = volterra_origin_pool.frontend.name
      namespace = var.f5xc_namespace
    }
    weight   = 1
    priority = 1
  }

  # HTTP en el CE — el tráfico desde internet llega al puerto 80 del CE
  # Para HTTPS: reemplazar http{} por https{} con un certificado TLS
  http {
    dns_volterra_managed = false
    port                 = "80"
  }

  # WAF, rate-limit y service policies desactivados por defecto — activar según necesidad
  disable_waf         = true
  no_challenge        = true
  disable_rate_limit  = true
  no_service_policies = true
  add_location        = true

  depends_on = [volterra_origin_pool.frontend]
}
