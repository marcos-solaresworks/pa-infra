#!/bin/bash

# ==========================================
# USER DATA SCRIPT - EC2 INITIALIZATION
# HG03 - Configurar Ambiente Base na AWS
# ==========================================

# Variáveis passadas pelo Terraform
RDS_ENDPOINT="${rds_endpoint}"
S3_BUCKET="${s3_bucket}"
PROJECT_NAME="${project_name}"

# Log de execução
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "=== Iniciando configuração da instância EC2 - $(date) ==="

# ==========================================
# ATUALIZAÇÃO DO SISTEMA
# ==========================================

echo "Atualizando sistema operacional..."
dnf update -y

# Instalar utilitários essenciais
dnf install -y \
    wget \
    curl \
    git \
    htop \
    tree \
    unzip \
    jq \
    postgresql15 \
    awscli2

# ==========================================
# INSTALAÇÃO DO DOCKER
# ==========================================

echo "Instalando Docker..."

# Instalar Docker
dnf install -y docker

# Iniciar e habilitar Docker
systemctl start docker
systemctl enable docker

# Adicionar usuário ec2-user ao grupo docker
usermod -a -G docker ec2-user

# ==========================================
# INSTALAÇÃO DO DOCKER COMPOSE
# ==========================================

echo "Instalando Docker Compose..."

# Download Docker Compose
DOCKER_COMPOSE_VERSION="2.24.1"
curl -L "https://github.com/docker/compose/releases/download/v$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Tornar executável
chmod +x /usr/local/bin/docker-compose

# Criar symlink para facilitar uso
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# ==========================================
# CONFIGURAÇÃO DE DIRETÓRIOS
# ==========================================

echo "Criando estrutura de diretórios..."

# Diretório principal do projeto
mkdir -p /opt/$${PROJECT_NAME}
mkdir -p /opt/$${PROJECT_NAME}/data
mkdir -p /opt/$${PROJECT_NAME}/logs
mkdir -p /opt/$${PROJECT_NAME}/configs

# Diretórios para aplicação
mkdir -p /opt/$${PROJECT_NAME}/api
mkdir -p /opt/$${PROJECT_NAME}/worker
mkdir -p /opt/$${PROJECT_NAME}/rabbitmq

# Permissões
chown -R ec2-user:ec2-user /opt/$${PROJECT_NAME}

# ==========================================
# CONFIGURAÇÃO INICIAL DOCKER COMPOSE
# ==========================================

echo "Criando arquivo docker-compose inicial..."

cat > /opt/$${PROJECT_NAME}/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Portainer - Gerenciamento de containers
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - app_network

  # RabbitMQ - Message Broker
  rabbitmq:
    image: rabbitmq:3-management
    container_name: rabbitmq
    restart: unless-stopped
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: GraficaMVP2025!
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - app_network

volumes:
  portainer_data:
  rabbitmq_data:

networks:
  app_network:
    driver: bridge
EOF

# ==========================================
# VARIÁVEIS DE AMBIENTE
# ==========================================

echo "Configurando variáveis de ambiente..."

# Criar arquivo de ambiente
cat > /opt/$${PROJECT_NAME}/.env << EOF
# Database Configuration
DB_HOST=$${RDS_ENDPOINT}
DB_PORT=5432
DB_NAME=grafica_db
DB_USER=postgres
DB_PASSWORD=GraficaMVP2025!

# S3 Configuration
S3_BUCKET=$${S3_BUCKET}
AWS_REGION=us-east-1

# RabbitMQ Configuration
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=GraficaMVP2025!

# Application Configuration
PROJECT_NAME=$${PROJECT_NAME}
ENVIRONMENT=development
LOG_LEVEL=INFO
EOF

# Definir permissões do arquivo .env
chmod 600 /opt/$${PROJECT_NAME}/.env
chown ec2-user:ec2-user /opt/$${PROJECT_NAME}/.env

# ==========================================
# TESTE DE CONECTIVIDADE
# ==========================================

echo "Testando conectividade com serviços..."

# Função para testar conexão S3
test_s3_connection() {
    echo "Testando acesso ao S3..."
    if aws s3 ls s3://$${S3_BUCKET} --region us-east-1; then
        echo "✅ Conexão com S3 OK"
        # Criar arquivo de teste
        echo "Teste de conectividade - $(date)" > /tmp/test-s3.txt
        aws s3 cp /tmp/test-s3.txt s3://$${S3_BUCKET}/tests/connectivity-test.txt --region us-east-1
        rm /tmp/test-s3.txt
    else
        echo "❌ Erro na conexão com S3"
    fi
}

# Função para testar conexão RDS
test_rds_connection() {
    echo "Testando conexão com RDS PostgreSQL..."
    if pg_isready -h $${RDS_ENDPOINT} -p 5432; then
        echo "✅ RDS PostgreSQL está acessível"
        
        # Testar conexão com credenciais
        export PGPASSWORD='GraficaMVP2025!'
        if psql -h $${RDS_ENDPOINT} -U postgres -d grafica_db -c "SELECT version();" > /dev/null 2>&1; then
            echo "✅ Autenticação no RDS OK"
        else
            echo "⚠️  RDS acessível mas aguardando inicialização completa"
        fi
    else
        echo "❌ RDS ainda não está acessível - aguardando inicialização"
    fi
}

# Aguardar serviços ficarem disponíveis
sleep 30

# Executar testes
test_s3_connection
test_rds_connection

# ==========================================
# INICIALIZAÇÃO DOS CONTAINERS
# ==========================================

echo "Iniciando containers básicos..."

# Navegar para diretório do projeto
cd /opt/$${PROJECT_NAME}

# Iniciar containers (Portainer e RabbitMQ)
docker-compose up -d

# Aguardar containers iniciarem
sleep 20

# Verificar status dos containers
docker ps

# ==========================================
# CONFIGURAÇÕES FINAIS
# ==========================================

echo "Aplicando configurações finais..."

# Configurar logrotate para logs da aplicação
cat > /etc/logrotate.d/$${PROJECT_NAME} << EOF
/opt/$${PROJECT_NAME}/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ec2-user ec2-user
}
EOF

# Criar script de status dos serviços
cat > /opt/$${PROJECT_NAME}/status.sh << 'EOF'
#!/bin/bash

echo "=== STATUS DOS SERVIÇOS ==="
echo ""

echo "🐳 Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "📊 Uso de Recursos:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memória: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
echo "Disco: $(df -h / | awk 'NR==2{print $5}')"
echo ""

echo "🌐 Endpoints Disponíveis:"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Portainer: http://$PUBLIC_IP:9000"
echo "RabbitMQ Management: http://$PUBLIC_IP:15672"
echo ""

echo "📝 Logs Recentes:"
echo "User Data: tail -10 /var/log/user-data.log"
echo "Docker: docker logs portainer --tail 5"
EOF

chmod +x /opt/$${PROJECT_NAME}/status.sh
chown ec2-user:ec2-user /opt/$${PROJECT_NAME}/status.sh

# ==========================================
# LIMPEZA E FINALIZAÇÃO
# ==========================================

echo "Limpando arquivos temporários..."
yum clean all

# Atualizar locate database
updatedb

# Criar arquivo de conclusão
echo "Configuração concluída em: $(date)" > /opt/$${PROJECT_NAME}/setup-complete.txt
echo "RDS Endpoint: $${RDS_ENDPOINT}" >> /opt/$${PROJECT_NAME}/setup-complete.txt
echo "S3 Bucket: $${S3_BUCKET}" >> /opt/$${PROJECT_NAME}/setup-complete.txt

echo ""
echo "🎉 Configuração da instância EC2 concluída com sucesso!"
echo "📍 Execute '/opt/$${PROJECT_NAME}/status.sh' para verificar o status dos serviços"
echo "🔗 Acesse Portainer em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000"
echo "=== Configuração finalizada - $(date) ==="