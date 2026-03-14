terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # La organización y workspace se configuran en runtime mediante las
  # variables de entorno TF_CLOUD_ORGANIZATION y TF_WORKSPACE
  cloud {
    workspaces {
      name = "eks-cluster"
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
# VPC
# -----------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = var.outside_subnets
  private_subnets = var.private_subnets
  intra_subnets   = var.workload_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  intra_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "subnet-type"                     = "workload"
  }

  tags = var.tags
}

# -----------------------------------------------
# Subnets dedicadas para F5 XC (sin route table associations)
# El módulo terraform-aws-modules/vpc asocia route tables a TODAS sus subnets,
# lo que impide que F5 XC gestione sus propias rutas. Por eso se crean estas
# subnets como recursos independientes, sin ninguna route table asociada.
# F5 XC las tomará durante action_apply y asignará sus propias route tables.
# -----------------------------------------------
resource "aws_subnet" "xc_outside" {
  count             = length(var.xc_outside_subnets)
  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.xc_outside_subnets[count.index]
  availability_zone = slice(data.aws_availability_zones.available.names, 0, 3)[count.index]

  tags = merge(var.tags, {
    Name             = "${var.cluster_name}-xc-outside-${count.index + 1}"
    "f5xc-subnet"    = "outside"
    "f5xc-managed"   = "true"
  })
}

resource "aws_subnet" "xc_inside" {
  count             = length(var.xc_inside_subnets)
  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.xc_inside_subnets[count.index]
  availability_zone = slice(data.aws_availability_zones.available.names, 0, 3)[count.index]

  tags = merge(var.tags, {
    Name             = "${var.cluster_name}-xc-inside-${count.index + 1}"
    "f5xc-subnet"    = "inside"
    "f5xc-managed"   = "true"
  })
}

resource "aws_subnet" "xc_workload" {
  count             = length(var.xc_workload_subnets)
  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.xc_workload_subnets[count.index]
  availability_zone = slice(data.aws_availability_zones.available.names, 0, 3)[count.index]

  tags = merge(var.tags, {
    Name             = "${var.cluster_name}-xc-workload-${count.index + 1}"
    "f5xc-subnet"    = "workload"
    "f5xc-managed"   = "true"
  })
}

# -----------------------------------------------
# EKS Cluster
# -----------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access          = true
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Node groups
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
