provider "aws" {
  region = "us-east-1"
}

# Data source to get available availability zones
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main_v2" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc-v2"
  }
}

# Criar subnets públicas e privadas
resource "aws_subnet" "public_v2" {
  count = 2
  vpc_id = aws_vpc.main_v2.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "public-subnet-v2-${count.index}"
    Tier  = "public"
  }
}

resource "aws_subnet" "private_v2" {
  count = 2
  vpc_id = aws_vpc.main_v2.id
  cidr_block = "10.0.${count.index + 2}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "private-subnet-v2-${count.index}"
    Tier  = "private"
  }
}

# Criar um gateway de internet
resource "aws_internet_gateway" "igw_v2" {
  vpc_id = aws_vpc.main_v2.id

  tags = {
    Name = "eks-igw-v2"
  }
}

# Criar uma tabela de rotas para a subnet pública
resource "aws_route_table" "public_v2" {
  vpc_id = aws_vpc.main_v2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_v2.id
  }

  tags = {
    Name = "public-route-table-v2"
  }
}

# Associar a tabela de rotas às subnets públicas
resource "aws_route_table_association" "public_v2" {
  count = 2
  subnet_id      = aws_subnet.public_v2[count.index].id
  route_table_id = aws_route_table.public_v2.id
}

# Criar o IAM role para o EKS
resource "aws_iam_role" "eks_role_v2" {
  name = "eks-role-v2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "Service": [
                    "ec2.amazonaws.com",
                    "eks.amazonaws.com"
                ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy_attach_v2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role_v2.name
}

# Criar o cluster EKS
resource "aws_eks_cluster" "eks_v2" {
  name     = "eks-cluster-v2"
  role_arn = aws_iam_role.eks_role_v2.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private_v2[0].id,
      aws_subnet.private_v2[1].id,
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy_attach_v2]
}

# Criar o IAM role para o Fargate
resource "aws_iam_role" "eks_fargate_role_v2" {
  name = "eks-fargate-role-v2"

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

resource "aws_iam_role_policy_attachment" "fargate_policy_attach_v2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_role_v2.name
}

# Criar o perfil de Fargate
resource "aws_eks_fargate_profile" "fargate_profile_v2" {
  cluster_name           = aws_eks_cluster.eks_v2.name
  fargate_profile_name   = "my-fargate-profile-v2"
  pod_execution_role_arn = aws_iam_role.eks_fargate_role_v2.arn
  subnet_ids             = [
    aws_subnet.private_v2[0].id,
    aws_subnet.private_v2[1].id,
  ]

  selector {
    namespace = "default"
  }

  depends_on = [aws_eks_cluster.eks_v2]
}

# Criar um grupo de segurança para o RDS
resource "aws_security_group" "db_sg_v2" {
  vpc_id = aws_vpc.main_v2.id

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
    Name = "db-sg-v2"
  }
}

# Criar o DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group_v2" {
  name       = "my-db-subnet-group-v2"
  subnet_ids = [
    aws_subnet.private_v2[0].id,
    aws_subnet.private_v2[1].id,
  ]
  tags = {
    Name = "my-db-subnet-group-v2"
  }
}

# Criar o banco de dados RDS
resource "aws_db_instance" "db_v2" {
  identifier              = "dbinstance-v2"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage       = 20
  storage_type           = "gp2"
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  vpc_security_group_ids = [aws_security_group.db_sg_v2.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group_v2.name  # Vincular o subnet group
  skip_final_snapshot    = true
  deletion_protection = true

  tags = {
    Name = "dbinstance-v2"
  }
}

data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["602401143452"] # Conta oficial da AWS para EKS

  filter {
    name   = "name"
    values = ["amazon-eks-node-*-v*"] # Padrão para AMIs de worker EKS
  }

  filter {
    name   = "architecture"
    values = ["x86_64"] # Verifique a arquitetura correta
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_launch_template" "node_group_template" {
  name_prefix   = "eks-node-template"
  image_id      = data.aws_ami.eks_worker.id  # Substitua pela AMI correta
  instance_type = "t3.micro"

  # Adicionando o Security Group do Cluster EKS
  vpc_security_group_ids = ["sg-077403eb57b605fd5"]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node"
    }
  }
}

resource "aws_eks_node_group" "node_group_v2" {
  cluster_name    = aws_eks_cluster.eks_v2.name
  node_group_name = "my-node-group-v2"
  node_role_arn   = aws_iam_role.eks_role_v2.arn
  subnet_ids      = [
    aws_subnet.private_v2[0].id,
    aws_subnet.private_v2[1].id,
  ]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Usando o Launch Template que contém o Security Group
  launch_template {
    id      = aws_launch_template.node_group_template.id
    version = "$Latest"  # ou especifique a versão, se preferir
  }

  tags = {
    Name = "my-node-group-v2"
  }

  depends_on = [aws_eks_cluster.eks_v2]
}

resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.eks_v2.name  # Atualize para o nome correto do cluster
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts_on_create = "OVERWRITE"  # Durante a criação
  resolve_conflicts_on_update = "OVERWRITE"   # Durante a atualização
}


variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
  default = [
    {
      name    = "kube-proxy"
      version = "v1.30.0-eksbuild.3"
    },
    {
      name    = "vpc-cni"
      version = "v1.18.1-eksbuild.3"
    },
    {
      name    = "coredns"
      version = "v1.11.3-eksbuild.1"
    }
  ]
}
