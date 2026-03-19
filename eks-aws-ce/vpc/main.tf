# ─────────────────────────────────────────────────────────────────────────────
# Layout de subnets derivado automáticamente de vpc_cidr + az_names:
#
#   /24 privadas (EKS nodes + CE inside):  índices 1, 2, ...
#   /24 outside  (CE exterior con IGW):    índices 10, 11, ...
#
# Ejemplo con vpc_cidr=10.0.0.0/16 y 2 AZs:
#   private[0] = 10.0.1.0/24  (us-east-1a) → EKS nodes + CE inside
#   private[1] = 10.0.2.0/24  (us-east-1b) → EKS nodes
#   outside[0] = 10.0.10.0/24 (us-east-1a) → CE exterior
# ─────────────────────────────────────────────────────────────────────────────

# ─── VPC ──────────────────────────────────────────────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "eks-aws-ce-vpc" })
}

# ─── Internet Gateway (para subnets outside del CE) ───────────────────────────
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "eks-aws-ce-igw" })
}

# ─── Subnets privadas (nodos EKS + interfaz inside del CE) ───────────────────
resource "aws_subnet" "private" {
  count             = length(var.az_names)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = var.az_names[count.index]
  tags              = merge(var.tags, { Name = "eks-aws-ce-private-${count.index}" })
}

# ─── Subnets outside (interfaz exterior del CE, con ruta a IGW) ───────────────
# Se crea una por AZ para soportar CE multi-AZ (HA). Para single-node solo se usa [0].
resource "aws_subnet" "outside" {
  count                   = length(var.az_names)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone       = var.az_names[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "eks-aws-ce-outside-${count.index}" })
}

# ─── EIP + NAT Gateway (para que los nodos EKS accedan a ECR/internet) ────────
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "eks-aws-ce-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.outside[0].id
  tags          = merge(var.tags, { Name = "eks-aws-ce-nat" })
  depends_on    = [aws_internet_gateway.this]
}

# ─── Tabla de rutas: outside → IGW ───────────────────────────────────────────
resource "aws_route_table" "outside" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "eks-aws-ce-rt-outside" })
}

resource "aws_route_table_association" "outside" {
  count          = length(aws_subnet.outside)
  subnet_id      = aws_subnet.outside[count.index].id
  route_table_id = aws_route_table.outside.id
}

# ─── Tabla de rutas: private → NAT ────────────────────────────────────────────
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = merge(var.tags, { Name = "eks-aws-ce-rt-private" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
