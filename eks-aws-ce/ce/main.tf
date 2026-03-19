# ─────────────────────────────────────────────────────────────────────────────
# 1. Cloud Credentials — registra las credenciales AWS en F5 XC
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_cloud_credentials" "aws" {
  name      = var.aws_credentials_name
  namespace = "system"

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
# 2. AWS VPC Site — registra el site en F5 XC usando la VPC creada en vpc/
#    vpc_id, outside_subnet_ids e inside_subnet_ids vienen como outputs del stack vpc/
#    Modo: ingress_egress_gw (multi-NIC) → outside para internet, inside hacia EKS
#    El dominio casos.accessq.com se gestiona en tu DNS propio, no en F5 XC.
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_aws_vpc_site" "ce" {
  name      = var.site_name
  namespace = "system"

  aws_region    = var.aws_region
  instance_type = var.ce_instance_type
  disk_size     = 80
  ssh_key       = var.ssh_key

  aws_cred {
    name      = volterra_cloud_credentials.aws.name
    namespace = "system"
  }

  vpc {
    vpc_id = var.vpc_id
  }

  ingress_egress_gw {
    aws_certified_hw = "aws-byol-multi-nic-voltmesh"

    no_dc_cluster_group      = true
    no_global_network        = true
    no_network_policy        = true
    no_inside_static_routes  = true
    no_outside_static_routes = true
    no_forward_proxy         = true
    sm_connection_public_ip  = true

    dynamic "az_nodes" {
      for_each = { for i, az in var.az_names : tostring(i) => az }
      content {
        aws_az_name = az_nodes.value

        outside_subnet {
          existing_subnet_id = var.outside_subnet_ids[tonumber(az_nodes.key)]
        }
        inside_subnet {
          existing_subnet_id = var.inside_subnet_ids[tonumber(az_nodes.key)]
        }
      }
    }
  }

  logs_streaming_disabled = true
  labels                  = var.labels

  depends_on = [volterra_cloud_credentials.aws]

  lifecycle {
    ignore_changes = [annotations]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Waiting — da tiempo a F5 XC para validar el site antes de hacer apply
# ─────────────────────────────────────────────────────────────────────────────
resource "time_sleep" "wait_for_site_validation" {
  create_duration = "120s"
  depends_on      = [volterra_aws_vpc_site.ce]
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. Apply — despliega físicamente el CE en AWS
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_tf_params_action" "deploy" {
  site_name       = volterra_aws_vpc_site.ce.name
  site_kind       = "aws_vpc_site"
  action          = "apply"
  wait_for_action = true

  depends_on = [time_sleep.wait_for_site_validation]
}
