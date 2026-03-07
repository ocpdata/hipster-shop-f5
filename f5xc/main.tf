# ─────────────────────────────────────────────────────────────────────────────
# 1. Cloud Credentials — guarda las credenciales AWS dentro de F5 XC
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_cloud_credentials" "aws" {
  name      = var.aws_credentials_name
  namespace = var.f5xc_namespace

  aws_secret_key {
    access_key = var.aws_access_key
    secret_key {
      clear_secret_info {
        url = "string:///${base64encode(var.aws_secret_key)}"
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. AWS VPC Site — declara el site en la nube de F5 XC
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_aws_vpc_site" "site" {
  name        = var.site_name
  namespace   = var.f5xc_namespace
  description = var.site_description

  aws_region    = var.aws_region
  instance_type = var.instance_type
  ssh_key       = var.ssh_key

  aws_cred {
    name      = volterra_cloud_credentials.aws.name
    namespace = var.f5xc_namespace
  }

  # VPC — se crea una nueva VPC con el CIDR indicado
  vpc {
    new_vpc {
      primary_ipv4 = var.vpc_cidr
    }
  }

  # Egress via Internet Gateway
  egress_gateway_default = true

  # Sin VIPs públicas (puede habilitarse después)
  disable_internet_vip = true

  # Security group gestionado por F5 XC
  f5xc_security_group = true

  # Sin Direct Connect
  direct_connect_disabled = true

  # Sin nodos worker adicionales
  no_worker_nodes = true

  # Sin routing especial
  f5_orchestrated_routing = true

  # Sin servicios bloqueados por defecto
  default_blocked_services = true

  # Modo Ingress/Egress Gateway (multi-NIC)
  # Subnets generadas con cidrsubnet:
  #   outside  index*3 + 1  →  AZ0=.1.0/24, AZ1=.4.0/24
  #   inside   index*3 + 2  →  AZ0=.2.0/24, AZ1=.5.0/24
  #   workload index*3 + 3  →  AZ0=.3.0/24, AZ1=.6.0/24
  ingress_egress_gw {
    aws_certified_hw = var.certified_hw

    no_dc_cluster_group      = true
    no_global_network        = true
    no_network_policy        = true
    no_inside_static_routes  = true
    no_outside_static_routes = true
    forward_proxy_allow_all  = true
    sm_connection_public_ip  = true

    dynamic "az_nodes" {
      for_each = var.az_names
      content {
        aws_az_name = az_nodes.value

        outside_subnet {
          subnet_param {
            ipv4 = cidrsubnet(var.vpc_cidr, 8, index(var.az_names, az_nodes.value) * 3 + 1)
          }
        }

        inside_subnet {
          subnet_param {
            ipv4 = cidrsubnet(var.vpc_cidr, 8, index(var.az_names, az_nodes.value) * 3 + 2)
          }
        }

        workload_subnet {
          subnet_param {
            ipv4 = cidrsubnet(var.vpc_cidr, 8, index(var.az_names, az_nodes.value) * 3 + 3)
          }
        }
      }
    }
  }

  # Logs enviados a F5 XC global controller
  logs_streaming_disabled = true

  labels = var.labels

  lifecycle {
    ignore_changes = [
      annotations,
    ]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Apply Terraform Params — lanza el despliegue real del site en AWS
#    (F5 XC ejecuta su propio Terraform interno para crear los recursos AWS)
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_tf_params_action" "apply_site" {
  site_name       = volterra_aws_vpc_site.site.name
  site_kind       = "aws_vpc_site"
  action          = "apply"
  wait_for_action = true

  depends_on = [volterra_aws_vpc_site.site]
}
