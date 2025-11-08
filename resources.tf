# ==========================================
# RECURSOS AWS - EC2, RDS, S3
# HG03 - Configurar Ambiente Base na AWS
# ==========================================

# ==========================================
# IAM ROLES E POLICIES
# ==========================================

# IAM Role para EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-ec2-role"
  })
}

# IAM Policy para acesso S3 e RDS
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Instance Profile para EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ==========================================
# EC2 INSTANCE
# ==========================================

# User Data Script para configuração inicial
locals {
  user_data = base64encode(templatefile("${path.module}/scripts/user-data.sh", {
    rds_endpoint = aws_db_instance.postgres.endpoint
    s3_bucket    = aws_s3_bucket.storage.bucket
    project_name = var.project_name
  }))
}

# Instância EC2
resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"  # Free Tier eligible - mais moderna que t2.micro
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.ec2_key_pair.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.ec2_volume_size
    encrypted   = true
    
    tags = merge(var.default_tags, {
      Name = "${var.project_name}-root-volume"
    })
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-ec2"
    Role = "Application-Server"
  })

  # Aguardar VPC e subnets estarem prontas
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table_association.public
  ]
}

# ==========================================
# RDS POSTGRESQL
# ==========================================

# Service Linked Role para RDS (necessário para criar instâncias RDS)
resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"
  description      = "Service Linked Role for Amazon RDS"

  # Ignore se já existir
  lifecycle {
    ignore_changes = [aws_service_name]
  }
}

# DB Subnet Group (requer pelo menos 2 AZs)
resource "aws_db_subnet_group" "postgres" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.public_2.id]

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

# Instância RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-postgres"
  allocated_storage      = var.rds_allocated_storage
  storage_type          = "gp3"
  engine                = "postgres"
  engine_version        = "15.7"
  instance_class        = var.rds_instance_class
  
  db_name  = var.rds_database_name
  username = var.rds_username
  password = var.rds_password
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  
  # Configurações Free Tier
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Free Tier - não Multi-AZ
  multi_az = false
  
  # Configurações de segurança
  storage_encrypted = true
  
  # Configurações para desenvolvimento
  publicly_accessible = true  # Para Free Tier sem NAT Gateway
  skip_final_snapshot = true  # Para facilitar destruição em dev
  
  # Performance Insights (Free Tier)
  performance_insights_enabled = false  # Evita custos extras
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-postgres"
    Engine = "PostgreSQL"
  })

  # Aguardar subnet group e service linked role estarem prontos
  depends_on = [
    aws_db_subnet_group.postgres,
    aws_iam_service_linked_role.rds
  ]
}

# ==========================================
# S3 BUCKET
# ==========================================

# Gerar nome único para bucket
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Bucket S3 principal
resource "aws_s3_bucket" "storage" {
  bucket = "${var.s3_bucket_prefix}-${random_string.bucket_suffix.result}"

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-storage"
    Type = "Primary-Storage"
  })
}

# Configuração de versionamento
resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configuração de criptografia
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acesso público (segurança)
resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration para otimizar custos
resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "transition_to_ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ==========================================
# CLOUDWATCH LOGS
# ==========================================

# Log Group para aplicação
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 7  # Free Tier - 5GB gratuitos

  # Tags removidas para evitar erro de permissão logs:ListTagsForResource
}