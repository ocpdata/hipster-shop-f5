terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    workspaces {
      name = "eks-3sn"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------
# Data sources
# -----------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------
# VPC — 1 subnet por AZ (3 subnets en total)
# -----------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = var.private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}

# -----------------------------------------------
# EKS Cluster
# -----------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      name           = "${var.cluster_name}-ng"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      labels = {
        Environment = var.environment
      }
    }
  }

  tags = var.tags
}

# -----------------------------------------------
# Permitir tráfico desde el CE de F5 XC (inside subnets) hacia los pods
# -----------------------------------------------
resource "aws_security_group_rule" "xc_ce_to_pods" {
  type              = "ingress"
  description       = "F5 XC CE inside network → EKS pods"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = var.xc_inside_cidr_blocks
  security_group_id = module.eks.node_security_group_id
}
