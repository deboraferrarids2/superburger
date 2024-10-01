# Output para o endpoint do RDS
output "rds_endpoint" {
  value = aws_db_instance.db_v2.endpoint
}

# Output para o ID do VPC
output "vpc_id" {
  value = aws_vpc.main_v2.id
}

# Outputs para subnets privadas
output "private_subnet_ids" {
  value = aws_subnet.private_v2[*].id
}

# Outputs para subnets públicas
output "public_subnet_ids" {
  value = aws_subnet.public_v2[*].id
}

# Output para o endpoint da instância do banco de dados
output "db_instance_endpoint" {
  value = aws_db_instance.db_v2.endpoint
}

# Output para o nome do cluster EKS
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_v2.name
}
