# -----------------------------------------------
# EKS Cluster — solo ClusterIP, sin ningún LB externo
# vpc_id y private_subnet_ids vienen del stack vpc/ vía outputs
# -----------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # API server privado — solo accesible desde dentro de la VPC
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids

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
# VPC Endpoints — para que nodos en subnets privadas
# puedan alcanzar ECR, STS, EC2, EKS y S3 sin internet
# -----------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.cluster_name}-vpc-endpoints"
  description = "Allow HTTPS from private subnets to VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

locals {
  vpc_endpoint_services = [
    "ecr.api",
    "ecr.dkr",
    "sts",
    "ec2",
    "eks",
    "autoscaling",
    "logs",
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.vpc_endpoint_services)

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.cluster_name}-${each.value}" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = merge(var.tags, { Name = "${var.cluster_name}-s3" })
}

# -----------------------------------------------
# Regla de ingress: permite tráfico desde las inside subnets del CE
# hacia los nodos EKS (pods usan ClusterIP, CE hace forward via VPC routing)
# -----------------------------------------------
resource "aws_security_group_rule" "ce_inside_to_pods" {
  type              = "ingress"
  description       = "F5 XC CE inside network to EKS nodes/pods"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  # El CE inside usa las mismas subnets privadas que los nodos EKS
  cidr_blocks       = var.private_subnet_cidrs
  security_group_id = module.eks.node_security_group_id
}
