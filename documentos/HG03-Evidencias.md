# 📸 **Evidências da Entrega - HG03**

**Documento de Apoio:** Capturas e provas da infraestrutura funcionando  
**Data:** 7 de novembro de 2025  

---

## 📂 **Estrutura de Evidências**

### 🖼️ **Screenshots Necessários** (a serem coletados)

#### 1. **Console AWS - Visão Geral**
- [ ] Dashboard EC2 mostrando instância t3.micro em execução
- [ ] Console RDS mostrando PostgreSQL disponível
- [ ] Console S3 mostrando bucket criado
- [ ] CloudWatch mostrando logs da aplicação

#### 2. **Terraform Outputs**
- [ ] Comando `terraform output` com todas as informações
- [ ] Estado do Terraform (`terraform show`)
- [ ] Lista de recursos criados

#### 3. **Conectividade SSH**
- [ ] Conexão SSH bem-sucedida à EC2
- [ ] Comando `docker ps` mostrando containers rodando
- [ ] Status dos serviços na EC2

#### 4. **Interfaces Web**
- [ ] Portainer Dashboard (http://IP:9000)
- [ ] RabbitMQ Management Interface (http://IP:15672)
- [ ] Logs de inicialização da EC2

#### 5. **Testes de Conectividade**
- [ ] Teste de conexão PostgreSQL (pg_isready)
- [ ] Upload/Download S3 via AWS CLI
- [ ] Status dos Security Groups

---

## 📋 **Comandos de Validação Executados**

### ✅ **Infraestrutura Terraform:**
```bash
terraform init
terraform plan
terraform apply
terraform output
```

### ✅ **Conectividade EC2:**
```bash
ssh -i keys/grafica-mvp-key.pem ec2-user@<IP>
docker ps
/opt/grafica-mvp/status.sh
tail -f /var/log/user-data.log
```

### ✅ **Testes RDS:**
```bash
pg_isready -h <RDS_ENDPOINT> -p 5432
psql -h <RDS_ENDPOINT> -U postgres -d grafica_db -c "SELECT version();"
```

### ✅ **Testes S3:**
```bash
aws s3 ls s3://grafica-mvp-storage-<suffix>/
echo "teste" | aws s3 cp - s3://grafica-mvp-storage-<suffix>/test.txt
aws s3 cp s3://grafica-mvp-storage-<suffix>/test.txt -
```

---

## 🔍 **Informações de Sistema**

### 🏗️ **Recursos Provisionados:**
```
VPC ID: vpc-xxxxxxxx
EC2 Instance ID: i-xxxxxxxx
RDS Identifier: grafica-mvp-postgres
S3 Bucket: grafica-mvp-storage-xxxxxxxx
```

### 🌐 **Endpoints:**
```
EC2 Public IP: X.X.X.X
RDS Endpoint: grafica-mvp-postgres.xxxxxx.us-east-1.rds.amazonaws.com:5432
S3 Bucket URL: s3://grafica-mvp-storage-xxxxxxxx
```

### 🔑 **Credenciais de Teste:**
```
SSH Key: keys/grafica-mvp-key.pem
DB User: postgres
DB Name: grafica_db
RabbitMQ User: admin
```

---

## ✅ **Checklist de Validação Final**

### 📊 **Critérios de Aceite:**
- [ ] **EC2 operacional com acesso remoto**
  - [ ] SSH funcionando
  - [ ] Docker containers rodando
  - [ ] Portainer acessível
  - [ ] RabbitMQ funcionando

- [ ] **Bucket S3 criado e testado**
  - [ ] Bucket criado com nome único
  - [ ] Upload de arquivo bem-sucedido
  - [ ] Download de arquivo bem-sucedido
  - [ ] Versionamento habilitado

- [ ] **Banco RDS configurado e acessível via API**
  - [ ] Instância PostgreSQL rodando
  - [ ] Conectividade da EC2 confirmada
  - [ ] Queries executando normalmente
  - [ ] Backup automático configurado

### 🔐 **Segurança:**
- [ ] Security Groups restritivos
- [ ] Criptografia habilitada
- [ ] IAM Roles configuradas
- [ ] Chaves SSH seguras

### 💰 **Free Tier:**
- [ ] Recursos dentro dos limites Free Tier
- [ ] Monitoramento de custos configurado
- [ ] Tags de identificação aplicadas

---

## 📝 **Observações da Implementação**

### 🎯 **Sucessos:**
- Terraform funcionando perfeitamente
- Todos os recursos provisionados com sucesso
- Conectividade entre serviços estabelecida
- Configuração automática via user-data funcionando

### ⚠️ **Desafios Superados:**
- Configuração de múltiplas AZs para RDS
- Permissões IAM para Service Linked Roles
- Compatibilidade entre t3.micro e Amazon Linux 2023
- S3 Lifecycle configuration warnings

### 🔄 **Melhorias Futuras:**
- Implementar monitoramento mais robusto
- Adicionar alertas CloudWatch
- Configurar backup automático para EC2
- Implementar rotação de logs