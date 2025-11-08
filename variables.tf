# ==========================================
# VARIÁVEIS DE CONFIGURAÇÃO
# HG03 - Configurar Ambiente Base na AWS
# ==========================================

variable "aws_region" {
  description = "Região AWS para deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "grafica-mvp"
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block para VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block para subnet pública 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block para subnet pública 2"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block para subnet privada"
  type        = string
  default     = "10.0.2.0/24"
}

# ==========================================
# VARIÁVEIS EC2
# ==========================================

variable "ec2_instance_type" {
  description = "Tipo da instância EC2 (Free Tier)"
  type        = string
  default     = "t3.micro"
}

variable "ec2_volume_size" {
  description = "Tamanho do volume EBS em GB (Free Tier: até 30GB)"
  type        = number
  default     = 20
}

# ==========================================
# VARIÁVEIS RDS
# ==========================================

variable "rds_instance_class" {
  description = "Classe da instância RDS (Free Tier)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Storage alocado para RDS em GB (Free Tier: até 20GB)"
  type        = number
  default     = 20
}

variable "rds_database_name" {
  description = "Nome da database inicial"
  type        = string
  default     = "grafica_db"
}

variable "rds_username" {
  description = "Username do administrador do RDS"
  type        = string
  default     = "postgres"
}

variable "rds_password" {
  description = "Senha do administrador do RDS"
  type        = string
  sensitive   = true
  default     = "GraficaMVP2025!"
}

# ==========================================
# VARIÁVEIS S3
# ==========================================

variable "s3_bucket_prefix" {
  description = "Prefixo para nome do bucket S3 (será adicionado timestamp)"
  type        = string
  default     = "grafica-mvp-storage"
}

# ==========================================
# TAGS PADRÃO
# ==========================================

variable "default_tags" {
  description = "Tags padrão para todos os recursos"
  type        = map(string)
  default = {
    Project     = "Grafica MVP"
    Environment = "Development" 
    Owner       = "Pos-Graduacao"
    ManagedBy   = "Terraform"
    CostCenter  = "MVP"
    Tier        = "FreeTier"
  }
}