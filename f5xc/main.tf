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

  aws_region = var.aws_region

  aws_cred {
    name      = volterra_cloud_credentials.aws.name
    namespace = var.f5xc_namespace
    tenant    = var.f5xc_tenant
  }

  # VPC — se crea una nueva VPC automáticamente
  vpc {
    new_vpc {
      autogenerate = length(var.vpc_cidr) == 0 ? true : null
      primary_ipv4 = length(var.vpc_cidr) > 0 ? var.vpc_cidr : null
    }
  }

  # Modo Ingress/Egress Gateway (multi-NIC)
  # Cada AZ recibe tres subnets generadas automáticamente con cidrsubnet:
  #   outside  (WAN → XC fabric):  index*3 + 1  →  AZ0=.1.0/24, AZ1=.4.0/24
  #   inside   (LAN → CE):          index*3 + 2  →  AZ0=.2.0/24, AZ1=.5.0/24
  #   workload (apps / pods):        index*3 + 3  →  AZ0=.3.0/24, AZ1=.6.0/24
  ingress_egress_gw {
    aws_certified_hw = var.certified_hw

    dynamic "az_nodes" {
      for_each = var.az_names
      content {
        aws_az_name = az_nodes.value

        outside_subnet {
          new_subnet {
            ipv4 = cidrsubnet(var.vpc_cidr, 8, index(var.az_names, az_nodes.value) * 3 + 1)
            az   = az_nodes.value
          }
        }

        inside_subnet {
          new_subnet {
            ipv4 = cidrsubnet(var.vpc_cidr, 8, index(var.az_names, az_nodes.value) * 3 + 2)
            az   = az_nodes.value
          }
        }

        workload_subnet {
          new_subnet {
            ipv4 = cidrsubnet(var.vpc_cidr, 8, index(var.az_names, az_nodes.value) * 3 + 3)
            az   = az_nodes.value
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
      # F5 XC puede añadir anotaciones internas; las ignoramos
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
