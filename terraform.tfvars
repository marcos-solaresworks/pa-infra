# ==========================================
# EXEMPLO DE ARQUIVO TERRAFORM.TFVARS
# HG03 - Configurar Ambiente Base na AWS
# 
# COPIE ESTE ARQUIVO PARA terraform.tfvars
# E AJUSTE OS VALORES CONFORME NECESSÁRIO
# ==========================================

# Configurações básicas do projeto
project_name = "grafica-mvp"
environment  = "dev"
aws_region   = "us-east-1"

# Configurações de rede
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"
public_subnet_2_cidr = "10.0.3.0/24"
private_subnet_cidr  = "10.0.2.0/24"

# Configurações EC2
ec2_instance_type = "t3.micro"
ec2_volume_size   = 20

# Configurações RDS
rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 20
rds_database_name     = "grafica_db"
rds_username          = "postgres"
rds_password          = "GraficaMVP2025!"  # ALTERE ESTA SENHA!

# Configurações S3
s3_bucket_prefix = "grafica-mvp-storage"

# Tags personalizadas (opcional)
default_tags = {
  Project     = "Grafica MVP"
  Environment = "Development"
  Owner       = "Pos-Graduacao"
  ManagedBy   = "Terraform"
  CostCenter  = "MVP"
  Tier        = "FreeTier"
  
  # Adicione suas tags personalizadas aqui
  Team        = "DevOps"
  Course      = "XPe-Pos-Graduacao"
}