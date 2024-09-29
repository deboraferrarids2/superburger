provider "aws" {
  region = "us-east-1"
}

# Data source to get available availability zones
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

# Criar subnets públicas e privadas
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "public-subnet-${count.index}"
    Tier  = "public"
  }
}

resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.${count.index + 2}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "private-subnet-${count.index}"
    Tier  = "private"
  }
}

# Criar um gateway de internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-igw"
  }
}

# Criar uma tabela de rotas para a subnet pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associar a tabela de rotas às subnets públicas
resource "aws_route_table_association" "public" {
  count = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Criar o IAM role para o EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

# Criar o cluster EKS
resource "aws_eks_cluster" "eks" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private[0].id,
      aws_subnet.private[1].id,
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy_attach]
}

# Criar o IAM role para o Fargate
resource "aws_iam_role" "eks_fargate_role" {
  name = "eks-fargate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"  # Service Principal para o Fargate
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "fargate_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_role.name
}


# Criar o perfil de Fargate
resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = aws_eks_cluster.eks.name
  fargate_profile_name   = "my-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn
  subnet_ids             = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id,
  ]

  selector {
    namespace = "default"
  }

  depends_on = [aws_eks_cluster.eks]
}


# Criar um grupo de segurança para o RDS
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Permitir acesso de dentro da VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Permitir saída para qualquer lugar
  }

  tags = {
    Name = "db-sg"
  }
}

# Criar o DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id,
  ]
  tags = {
    Name = "my-db-subnet-group"
  }
}

# Criar o banco de dados RDS
resource "aws_db_instance" "db" {
  identifier              = "dbinstance"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage       = 20
  storage_type           = "gp2"
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name  # Vincular o subnet group
  skip_final_snapshot    = true

  tags = {
    Name = "dbinstance"
  }
}