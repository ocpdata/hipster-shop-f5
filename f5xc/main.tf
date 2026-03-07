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
  disk_size     = 80
  ssh_key       = var.ssh_key

  aws_cred {
    name      = volterra_cloud_credentials.aws.name
    namespace = var.f5xc_namespace
  }

  # VPC — se crea una nueva VPC con el CIDR indicado
  vpc {
    new_vpc {
      name_tag     = var.site_name
      primary_ipv4 = var.vpc_cidr
    }
  }

  # Modo Ingress/Egress Gateway (multi-NIC)
  ingress_egress_gw {
    aws_certified_hw = var.certified_hw

    no_dc_cluster_group      = true
    no_global_network        = true
    no_network_policy        = true
    no_inside_static_routes  = true
    no_outside_static_routes = true
    no_forward_proxy         = true

    dynamic "az_nodes" {
      for_each = var.az_names
      content {
        aws_az_name = az_nodes.value

        outside_subnet {
          subnet_param {
            ipv4 = cidrsubnet(var.vpc_cidr, 8, index(var.az_names, az_nodes.value) * 2 + 1)
          }
        }

        inside_subnet {
          subnet_param {
            ipv4 = cidrsubnet(var.vpc_cidr, 8, index(var.az_names, az_nodes.value) * 2 + 2)
          }
        }
      }
    }
  }

  logs_streaming_disabled = true

  labels = var.labels

  lifecycle {
    ignore_changes = [
      annotations,
    ]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Espera a que F5 XC complete la validación interna de config del site
#    (la validación es asíncrona; sin espera, el apply_site falla con
#    "config validation did not succeed")
# ─────────────────────────────────────────────────────────────────────────────
resource "time_sleep" "wait_for_site_validation" {
  create_duration = "90s"
  depends_on      = [volterra_aws_vpc_site.site]
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. Apply Terraform Params — lanza el despliegue real del site en AWS
#    (F5 XC ejecuta su propio Terraform interno para crear los recursos AWS)
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_tf_params_action" "apply_site" {
  site_name       = volterra_aws_vpc_site.site.name
  site_kind       = "aws_vpc_site"
  action          = "apply"
  wait_for_action = true

  depends_on = [time_sleep.wait_for_site_validation]
}
