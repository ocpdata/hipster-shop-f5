provider "volterra" {
  api_p12_file = var.xc_api_p12_file
  url          = var.xc_api_url
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Obtiene el CIDR de la VPC existente para los Security Groups
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Crea la Global Virtual Network en F5 XC para conectividad multi-cloud
resource "volterra_virtual_network" "global" {
  name      = "${var.site_name}-global-vn"
  namespace = "system"

  global_network = true
}

# Security Group para la interfaz outside (SLO) del nodo XC
resource "aws_security_group" "outside" {
  name        = "f5xc-outside-sg"
  description = "F5 XC outside (SLO) interface security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "IPSec NAT-T"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "IKE"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "XC control plane"
    from_port   = 65500
    to_port     = 65500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VPC local traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.site_name}-outside-sg"
  }
}

# Security Group para la interfaz inside (SLI) del nodo XC
resource "aws_security_group" "inside" {
  name        = "f5xc-inside-sg"
  description = "F5 XC inside (SLI) interface security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.site_name}-inside-sg"
  }
}

module "aws_vpc_site" {
  source  = "f5devcentral/aws-vpc-site/xc"
  version = "0.0.12"

  site_name             = var.site_name
  aws_region            = var.aws_region
  site_type             = "ingress_egress_gw"
  master_nodes_az_names = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  # Usa una VPC existente en lugar de crear una nueva
  create_aws_vpc            = false
  vpc_id                    = var.vpc_id
  existing_outside_subnets  = var.existing_outside_subnets
  existing_inside_subnets   = var.existing_inside_subnets
  existing_workload_subnets = var.existing_workload_subnets

  # Security groups explícitos para interfaz outside e inside
  custom_security_group = {
    outside_security_group_id = aws_security_group.outside.id
    inside_security_group_id  = aws_security_group.inside.id
  }

  aws_cloud_credentials_name = module.aws_cloud_credentials.name
  block_all_services         = false

  global_network_connections_list = [{
    sli_to_global_dr = {
      global_vn = {
        name      = volterra_virtual_network.global.name
        namespace = "system"
      }
    }
  }]

  tags = {
    site = var.site_name
    managed-by = "terraform"
  }

  depends_on = [
    module.aws_cloud_credentials,
    volterra_virtual_network.global,
    aws_security_group.outside,
    aws_security_group.inside,
  ]
}

module "aws_cloud_credentials" {
  source  = "f5devcentral/aws-cloud-credentials/xc"
  version = "0.0.4"

  tags = {
    site       = var.site_name
    managed-by = "terraform"
  }

  name           = "${var.site_name}-creds"
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
}
