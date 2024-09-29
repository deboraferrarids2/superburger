output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "vpc_id" {
  value = aws_vpc.main.id
}
