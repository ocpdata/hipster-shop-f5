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
# 2. VPC & Subnets — creados directamente con el provider AWS
#    El módulo oficial usa este mismo patrón internamente.
#    Al crearlos aquí tenemos control total sobre el timing.
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_vpc" "site" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.labels, { Name = var.site_name })
}

resource "aws_internet_gateway" "site" {
  vpc_id = aws_vpc.site.id
  tags   = merge(var.labels, { Name = "${var.site_name}-igw" })
}

resource "aws_subnet" "outside" {
  count             = length(var.master_nodes_az_names)
  vpc_id            = aws_vpc.site.id
  cidr_block        = var.outside_subnets[count.index]
  availability_zone = var.master_nodes_az_names[count.index]
  tags              = merge(var.labels, { Name = "${var.site_name}-outside-${count.index}" })
}

resource "aws_subnet" "inside" {
  count             = length(var.master_nodes_az_names)
  vpc_id            = aws_vpc.site.id
  cidr_block        = var.inside_subnets[count.index]
  availability_zone = var.master_nodes_az_names[count.index]
  tags              = merge(var.labels, { Name = "${var.site_name}-inside-${count.index}" })
}

resource "aws_subnet" "workload" {
  count             = length(var.master_nodes_az_names)
  vpc_id            = aws_vpc.site.id
  cidr_block        = var.workload_subnets[count.index]
  availability_zone = var.master_nodes_az_names[count.index]
  tags              = merge(var.labels, { Name = "${var.site_name}-workload-${count.index}" })
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. AWS VPC Site — registra el site en F5 XC referenciando IDs reales de AWS
#    Usar existing_subnet_id (no subnet_param) es el patrón correcto que pasa
#    la validación de configuración de F5 XC.
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_aws_vpc_site" "this" {
  name      = var.site_name
  namespace = var.f5xc_namespace

  aws_region    = var.aws_region
  instance_type = var.instance_type
  disk_size     = 80
  ssh_key       = var.ssh_key

  aws_cred {
    name      = volterra_cloud_credentials.aws.name
    namespace = var.f5xc_namespace
  }

  vpc {
    vpc_id = aws_vpc.site.id
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
      for_each = { for i, az in var.master_nodes_az_names : tostring(i) => az }
      content {
        aws_az_name = az_nodes.value

        outside_subnet {
          existing_subnet_id = aws_subnet.outside[tonumber(az_nodes.key)].id
        }
        inside_subnet {
          existing_subnet_id = aws_subnet.inside[tonumber(az_nodes.key)].id
        }
        workload_subnet {
          existing_subnet_id = aws_subnet.workload[tonumber(az_nodes.key)].id
        }
      }
    }
  }

  logs_streaming_disabled = true
  labels                  = var.labels

  depends_on = [
    volterra_cloud_credentials.aws,
    aws_subnet.outside,
    aws_subnet.inside,
    aws_subnet.workload,
  ]

  lifecycle {
    ignore_changes = [annotations]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. Espera a que F5 XC complete la validación asíncrona del site
#    120 segundos para dar margen suficiente al proceso de validación.
# ─────────────────────────────────────────────────────────────────────────────
resource "time_sleep" "wait_for_site_validation" {
  create_duration = "120s"
  depends_on      = [volterra_aws_vpc_site.this]
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. Apply Terraform Params — lanza el despliegue real del site en AWS
# ─────────────────────────────────────────────────────────────────────────────
resource "volterra_tf_params_action" "action_apply" {
  site_name       = volterra_aws_vpc_site.this.name
  site_kind       = "aws_vpc_site"
  action          = "apply"
  wait_for_action = true

  depends_on = [time_sleep.wait_for_site_validation]
}
