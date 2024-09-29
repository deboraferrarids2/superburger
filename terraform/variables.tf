variable "db_username" {
  description = "Usuário do banco de dados RDS"
}

variable "db_password" {
  description = "Senha do banco de dados RDS"
  sensitive   = true
}

variable "db_name" {
  description = "Nome do banco de dados"
  default     = "challengedb"
}
