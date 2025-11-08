# 🚀 HG03 - Configurar Ambiente Base na AWS

## 📝 Descrição

Este diretório contém os arquivos Terraform para provisionamento da infraestrutura base na AWS conforme definido na HG02. A infraestrutura é otimizada para **AWS Free Tier** e inclui:

- **EC2 t2.micro** com Docker e Portainer
- **RDS PostgreSQL t3.micro** 
- **S3 Bucket** com versionamento e criptografia
- **VPC** com subnets e security groups
- **Key Pair** gerado automaticamente

## 📁 Estrutura dos Arquivos

```
HG03 - Configurar ambiente base na AWS/
├── main.tf              # Recursos principais (VPC, Security Groups)
├── variables.tf         # Variáveis de configuração
├── resources.tf         # EC2, RDS, S3 e IAM
├── outputs.tf           # Informações de saída
├── scripts/
│   └── user-data.sh     # Script de inicialização EC2
├── keys/               # Chaves SSH (criado automaticamente)
└── README.md           # Este arquivo
```

## 🚀 Como Executar

### 1️⃣ Pré-requisitos

```bash
# Instalar Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Configurar AWS CLI
aws configure
# Inserir Access Key ID, Secret Access Key, Region (us-east-1)
```

### 2️⃣ Inicialização

```bash
# Navegar para o diretório
cd "HG03 - Configurar ambiente base na AWS"

# Inicializar Terraform
terraform init

# Validar configuração
terraform validate

# Visualizar o que será criado
terraform plan
```

### 3️⃣ Deployment

```bash
# Aplicar infraestrutura
terraform apply

# Confirmar com 'yes' quando solicitado
```

### 4️⃣ Acesso à Infraestrutura

Após o deployment, use os outputs para acessar:

```bash
# Ver todas as informações
terraform output

# Conectar via SSH
terraform output ssh_connection
# Executar o comando retornado

# Verificar status dos serviços
terraform output -raw useful_commands
```

## 🔗 Endpoints de Acesso

Após o deployment, você terá acesso a:

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **SSH** | `ssh -i keys/grafica-mvp-key.pem ec2-user@<IP>` | Chave SSH |
| **Portainer** | `http://<IP>:9000` | Configurar no primeiro acesso |
| **RabbitMQ** | `http://<IP>:15672` | admin / GraficaMVP2025! |
| **PostgreSQL** | `<RDS_ENDPOINT>:5432` | postgres / GraficaMVP2025! |

## ⚙️ Configurações Personalizáveis

Edite o arquivo `terraform.tfvars` para personalizar:

```hcl
# Criar arquivo terraform.tfvars
project_name = "meu-projeto"
environment  = "dev"

# Senhas (recomendado usar AWS Secrets Manager em produção)
rds_password = "MinhaSenh@Segura123!"

# Recursos
ec2_instance_type = "t2.micro"
rds_instance_class = "db.t3.micro"
```

## 🛡️ Segurança Implementada

### 🔐 Network Security
- VPC isolada com CIDR 10.0.0.0/16
- Security Groups restritivos
- RDS acessível apenas do EC2

### 🔑 IAM & Access
- IAM Roles com least privilege
- Key Pair gerado automaticamente
- Chave privada salva localmente com permissões 600

### 🔒 Encryption
- EBS volumes criptografados
- RDS storage criptografado  
- S3 server-side encryption (AES256)

## 📊 Monitoramento

### CloudWatch Logs
- Log Group: `/aws/ec2/grafica-mvp`
- Retenção: 7 dias (Free Tier)

### Scripts Úteis
```bash
# Status dos serviços na EC2
ssh -i keys/grafica-mvp-key.pem ec2-user@<IP> '/opt/grafica-mvp/status.sh'

# Logs de inicialização
ssh -i keys/grafica-mvp-key.pem ec2-user@<IP> 'tail -f /var/log/user-data.log'

# Containers Docker
ssh -i keys/grafica-mvp-key.pem ec2-user@<IP> 'docker ps'
```

## 🧪 Testes de Conectividade

### Teste S3
```bash
# Listar bucket
aws s3 ls s3://<BUCKET_NAME>/ --region us-east-1

# Upload de teste
echo "teste" | aws s3 cp - s3://<BUCKET_NAME>/test.txt --region us-east-1
```

### Teste RDS
```bash
# Teste de conectividade
pg_isready -h <RDS_ENDPOINT> -p 5432

# Conexão com psql
psql -h <RDS_ENDPOINT> -U postgres -d grafica_db
```

### Teste Docker
```bash
# Via SSH na EC2
ssh -i keys/grafica-mvp-key.pem ec2-user@<IP>

# Verificar containers
docker ps

# Logs do Portainer
docker logs portainer

# Logs do RabbitMQ
docker logs rabbitmq
```

## 💰 Custos Free Tier

| Recurso | Limite Free Tier | Duração |
|---------|------------------|---------|
| EC2 t2.micro | 750 horas/mês | 12 meses |
| RDS t3.micro | 750 horas/mês | 12 meses |
| EBS Storage | 30GB | 12 meses |
| RDS Storage | 20GB | 12 meses |
| S3 Standard | 5GB | 12 meses |
| Data Transfer | 1GB/mês saída | Sempre |

**⚠️ Importante:** Monitore o uso para não exceder os limites do Free Tier.

## 🗑️ Destruição da Infraestrutura

```bash
# CUIDADO: Isso apagará TODOS os recursos
terraform destroy

# Confirmar com 'yes' quando solicitado
```

## 🔧 Troubleshooting

### Problemas Comuns

#### 1. Erro de Key Pair já existe
```bash
# Remover key pair existente
aws ec2 delete-key-pair --key-name grafica-mvp-key --region us-east-1
terraform apply
```

#### 2. Bucket S3 já existe
O nome é gerado automaticamente com sufixo aleatório, mas se houver conflito:
```bash
# Editar variables.tf e alterar s3_bucket_prefix
```

#### 3. RDS demorou para inicializar
```bash
# Verificar status
aws rds describe-db-instances --db-instance-identifier grafica-mvp-postgres
```

#### 4. EC2 não finaliza inicialização
```bash
# Ver logs de user-data
ssh -i keys/grafica-mvp-key.pem ec2-user@<IP> 'cat /var/log/user-data.log'
```

## 📞 Suporte

Para problemas ou dúvidas:
1. Verificar logs: `/var/log/user-data.log`
2. Verificar status: `/opt/grafica-mvp/status.sh`
3. Consultar documentação AWS
4. Verificar limites Free Tier no console AWS

---

> 🎯 **Próximos Passos**: Após a infraestrutura estar funcionando, proceder com o desenvolvimento da API .NET 8 e Worker conforme próximas histórias do backlog.