# ─────────────────────────────────────────────────────────────────────────────
# Layout de subnets derivado automáticamente de vpc_cidr + az_names:
#
#   /24 nat_public (NAT GW dedicado, F5 XC no lo usa): índice 0
#   /24 private    (nodos EKS, ruta → NAT GW):         índices 1, 2, ...
#   /24 ce_inside  (interfaz inside del CE, sin RT):   índice 5
#   /24 ce_outside (interfaz outside del CE, sin RT):  índice 10
#
# F5 XC requiere que los subnets que gestiona NO tengan asociaciones de
# route tables externas. Por eso ce_inside y ce_outside no tienen ninguna
# asociación — F5 XC creará y gestionará sus propias route tables.
#
# El NAT GW vive en nat_public (índice 0) para que los nodos EKS puedan
# acceder a ECR/internet sin interferir con los subnets del CE.
#
# Ejemplo con vpc_cidr=10.0.0.0/16 y az_names=["us-east-1a","us-east-1b"]:
#   nat_public  = 10.0.0.0/24  (us-east-1a) → NAT GW + IGW
#   private[0]  = 10.0.1.0/24  (us-east-1a) → EKS nodes
#   private[1]  = 10.0.2.0/24  (us-east-1b) → EKS nodes
#   ce_inside   = 10.0.5.0/24  (us-east-1a) → CE inside (sin route table)
#   ce_outside  = 10.0.10.0/24 (us-east-1a) → CE outside (sin route table)
# ─────────────────────────────────────────────────────────────────────────────

# ─── VPC ──────────────────────────────────────────────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "eks-aws-ce-vpc" })
}

# ─── Internet Gateway ─────────────────────────────────────────────────────────
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "eks-aws-ce-igw" })
}

# ─── Subnet NAT público (solo para el NAT GW, F5 XC no lo usa) ───────────────
# Tiene la route table con ruta al IGW para que el NAT GW pueda salir a internet.
resource "aws_subnet" "nat_public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 0)
  availability_zone       = var.az_names[0]
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "eks-aws-ce-nat-public" })
}

resource "aws_route_table" "nat_public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "eks-aws-ce-rt-nat-public" })
}

resource "aws_route_table_association" "nat_public" {
  subnet_id      = aws_subnet.nat_public.id
  route_table_id = aws_route_table.nat_public.id
}

# ─── EIP + NAT Gateway (en el subnet público dedicado) ────────────────────────
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
  tags       = merge(var.tags, { Name = "eks-aws-ce-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.nat_public.id
  tags          = merge(var.tags, { Name = "eks-aws-ce-nat" })
  depends_on    = [aws_internet_gateway.this]
}

# ─── Subnets privadas (nodos EKS, con ruta a NAT GW) ─────────────────────────
resource "aws_subnet" "private" {
  count             = length(var.az_names)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = var.az_names[count.index]
  tags              = merge(var.tags, { Name = "eks-aws-ce-private-${count.index}" })
}

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

# ─── Subnet CE inside (interfaz inside del CE, SIN route table) ───────────────
# F5 XC necesita que este subnet NO tenga asociaciones de route tables externas.
# Solo usa la route table main de la VPC (rutas locales únicamente).
# El CE alcanza los pods/servicios de EKS via routing local de la VPC.
resource "aws_subnet" "ce_inside" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 5)
  availability_zone = var.az_names[0]
  tags              = merge(var.tags, { Name = "eks-aws-ce-ce-inside" })
}

# ─── Subnet CE outside (interfaz exterior del CE, SIN route table) ────────────
# F5 XC necesita que este subnet NO tenga asociaciones de route tables externas.
# F5 XC creará su propia route table con ruta al IGW para la salida a internet.
resource "aws_subnet" "ce_outside" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 10)
  availability_zone       = var.az_names[0]
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "eks-aws-ce-ce-outside" })
}

