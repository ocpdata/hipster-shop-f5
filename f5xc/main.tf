# ─────────────────────────────────────────────────────────────────────────────
# 1. Cloud Credentials — guarda las credenciales AWS dentro de F5 XC
#    El módulo oficial recibe el NOMBRE del objeto, no lo crea.
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
# 2. AWS VPC Site — módulo oficial de F5
#    Crea la VPC y las subnets con el provider AWS, luego registra el site
#    en F5 XC usando existing_subnet_id (evita el error de validación de config).
# ─────────────────────────────────────────────────────────────────────────────
module "aws_vpc_site" {
  source  = "f5devcentral/aws-vpc-site/xc"
  version = "0.0.12"

  site_name   = var.site_name
  site_type   = "ingress_egress_gw"
  aws_region  = var.aws_region

  # VPC
  vpc_cidr = var.vpc_cidr

  # Subnets — se crean con el provider AWS y se referencian por ID en F5 XC
  master_nodes_az_names = var.master_nodes_az_names
  inside_subnets        = var.inside_subnets
  outside_subnets       = var.outside_subnets
  workload_subnets      = var.workload_subnets

  # Credenciales & acceso
  aws_cloud_credentials_name = volterra_cloud_credentials.aws.name
  ssh_key                    = var.ssh_key
  instance_type              = var.instance_type

  # Labels
  tags = var.labels

  depends_on = [volterra_cloud_credentials.aws]
}
