# ==========================================
# OUTPUTS - INFORMAÇÕES DOS RECURSOS
# HG03 - Configurar Ambiente Base na AWS
# ==========================================

# ==========================================
# INFORMAÇÕES DE CONECTIVIDADE
# ==========================================

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.main.public_ip
}

output "ec2_public_dns" {
  description = "DNS público da instância EC2"
  value       = aws_instance.main.public_dns
}

output "ec2_private_ip" {
  description = "IP privado da instância EC2"
  value       = aws_instance.main.private_ip
}

output "rds_endpoint" {
  description = "Endpoint do RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "Porta do RDS PostgreSQL"
  value       = aws_db_instance.postgres.port
}

output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.storage.arn
}

# ==========================================
# INFORMAÇÕES DE ACESSO
# ==========================================

output "ssh_connection" {
  description = "Comando SSH para conectar à instância EC2"
  value       = "ssh -i keys/${var.project_name}-key.pem ec2-user@${aws_instance.main.public_ip}"
}

output "key_pair_name" {
  description = "Nome do Key Pair criado"
  value       = aws_key_pair.ec2_key_pair.key_name
}

output "private_key_path" {
  description = "Caminho local da chave privada"
  value       = "keys/${var.project_name}-key.pem"
}

# ==========================================
# URLS DE ACESSO WEB
# ==========================================

output "portainer_url" {
  description = "URL do Portainer (gerenciamento Docker)"
  value       = "http://${aws_instance.main.public_ip}:9000"
}

output "rabbitmq_management_url" {
  description = "URL do RabbitMQ Management"
  value       = "http://${aws_instance.main.public_ip}:15672"
}

output "api_base_url" {
  description = "URL base para API .NET (quando deployada)"
  value       = "http://${aws_instance.main.public_ip}:5000"
}

# ==========================================
# INFORMAÇÕES DE REDE
# ==========================================

output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "subnet_public_id" {
  description = "ID da subnet pública 1"
  value       = aws_subnet.public.id
}

output "subnet_public_2_id" {
  description = "ID da subnet pública 2"
  value       = aws_subnet.public_2.id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "security_group_ec2_id" {
  description = "ID do Security Group do EC2"
  value       = aws_security_group.ec2_sg.id
}

output "security_group_rds_id" {
  description = "ID do Security Group do RDS"
  value       = aws_security_group.rds_sg.id
}

# ==========================================
# CREDENCIAIS E CONFIGURAÇÕES
# ==========================================

output "database_credentials" {
  description = "Credenciais do banco de dados"
  value = {
    endpoint = aws_db_instance.postgres.endpoint
    port     = aws_db_instance.postgres.port
    database = aws_db_instance.postgres.db_name
    username = aws_db_instance.postgres.username
  }
  sensitive = false
}

output "rabbitmq_credentials" {
  description = "Credenciais do RabbitMQ"
  value = {
    host     = aws_instance.main.public_ip
    port     = 5672
    username = "admin"
    management_port = 15672
  }
  sensitive = false
}

# ==========================================
# COMANDOS ÚTEIS
# ==========================================

output "useful_commands" {
  description = "Comandos úteis para gerenciamento"
  value = {
    ssh_connect     = "ssh -i keys/${var.project_name}-key.pem ec2-user@${aws_instance.main.public_ip}"
    check_status    = "ssh -i keys/${var.project_name}-key.pem ec2-user@${aws_instance.main.public_ip} '/opt/${var.project_name}/status.sh'"
    view_logs       = "ssh -i keys/${var.project_name}-key.pem ec2-user@${aws_instance.main.public_ip} 'tail -f /var/log/user-data.log'"
    docker_ps       = "ssh -i keys/${var.project_name}-key.pem ec2-user@${aws_instance.main.public_ip} 'docker ps'"
    s3_list         = "aws s3 ls s3://${aws_s3_bucket.storage.bucket}/ --region ${var.aws_region}"
    db_connect      = "psql -h ${aws_db_instance.postgres.endpoint} -U ${aws_db_instance.postgres.username} -d ${aws_db_instance.postgres.db_name}"
  }
}

# ==========================================
# INFORMAÇÕES DE CUSTOS
# ==========================================

output "free_tier_resources" {
  description = "Recursos utilizando Free Tier"
  value = {
    ec2_instance     = "t2.micro (750h/mês gratuitas por 12 meses)"
    rds_instance     = "db.t3.micro (750h/mês gratuitas por 12 meses)"
    ebs_storage      = "${var.ec2_volume_size}GB (30GB gratuitos por 12 meses)"
    rds_storage      = "${var.rds_allocated_storage}GB (20GB gratuitos por 12 meses)"
    s3_storage       = "5GB Standard gratuitos por 12 meses"
    data_transfer    = "1GB/mês de saída gratuito"
  }
}

output "cost_optimization_tips" {
  description = "Dicas para otimização de custos"
  value = [
    "Monitore o uso através do AWS Cost Explorer",
    "Configure alertas de billing",
    "Pare instâncias EC2 quando não estiver usando",
    "Use S3 Lifecycle policies para dados antigos",
    "Configure CloudWatch alarms para monitoramento"
  ]
}