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
# Data sources — VPC y subnets existentes
# -----------------------------------------------
data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_subnet" "workload" {
  id = var.workload_subnet_id
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

  vpc_id                   = data.aws_vpc.existing.id
  subnet_ids               = [var.workload_subnet_id]
  control_plane_subnet_ids = [var.workload_subnet_id]

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
