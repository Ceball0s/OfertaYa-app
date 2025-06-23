# 🚀 Guía de Despliegue en AWS Free Tier - OfertaYa

## 📊 **Análisis de tu Plan Gratuito AWS**

Según tu dashboard de AWS, tienes disponible:

### **✅ Servicios Disponibles:**
- **EC2**: 750 horas/mes (12 meses gratis) - **621 horas restantes**
- **EBS**: 30 GB-mes (12 meses gratis) - **27 GB restantes**  
- **VPC**: 750 horas/mes (12 meses gratis) - **655 horas restantes**
- **S3**: 2000 requests/mes (12 meses gratis) - **1999 requests restantes**
- **Data Transfer**: 100 GB salida/mes (siempre gratis)

### **🎯 ¿Es suficiente para OfertaYa?**
**¡SÍ!** Tu plan gratuito puede soportar perfectamente OfertaYa con optimizaciones.

## 🏗️ **Estrategia de Despliegue Optimizada**

### **Configuración Recomendada:**
- **1 instancia EC2 t2.micro** (730 horas/mes)
- **1 base de datos PostgreSQL** consolidada
- **Docker Compose** para orquestar servicios
- **Límites de recursos** para evitar exceder el plan gratuito

## 📋 **Pasos para el Despliegue**

### **Paso 1: Instalar AWS CLI**
```bash
# Windows (PowerShell como administrador)
winget install -e --id Amazon.AWSCLI

# Verificar instalación
aws --version
```

### **Paso 2: Configurar AWS CLI**
```bash
aws configure
# AWS Access Key ID: [tu_access_key]
# AWS Secret Access Key: [tu_secret_key]
# Default region name: us-east-2
# Default output format: json
```

### **Paso 3: Crear Key Pair**
```bash
# Crear key pair para SSH
aws ec2 create-key-pair --key-name ofertaya-key --query 'KeyMaterial' --output text > ofertaya-key.pem

# En Windows, cambiar permisos
icacls ofertaya-key.pem /inheritance:r
icacls ofertaya-key.pem /grant:r "%USERNAME%:R"
```

### **Paso 4: Crear Security Group**
```bash
# Crear security group
aws ec2 create-security-group \
  --group-name ofertaya-sg \
  --description "Security group for OfertaYa application"

# Obtener el ID del security group
SG_ID=$(aws ec2 describe-security-groups --group-names ofertaya-sg --query 'SecurityGroups[0].GroupId' --output text)

# Abrir puertos necesarios
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3001 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 9090 \
  --cidr 0.0.0.0/0
```

### **Paso 5: Crear Instancia EC2**
```bash
# Obtener AMI ID de Ubuntu 22.04
AMI_ID=$(aws ssm get-parameters --names /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id --query 'Parameters[0].Value' --output text)

# Crear instancia EC2
aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type t2.micro \
  --key-name ofertaya-key \
  --security-group-ids $SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=OfertaYa-Server}]'

# Obtener IP pública
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=OfertaYa-Server" --query 'Reservations[0].Instances[0].InstanceId' --output text)
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "IP Pública: $PUBLIC_IP"
```

### **Paso 6: Instalar Docker en la Instancia**
```bash
# Conectar por SSH y instalar Docker
ssh -i ofertaya-key.pem ubuntu@$PUBLIC_IP << 'EOF'
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker ubuntu
sudo systemctl start docker
sudo systemctl enable docker
EOF
```

### **Paso 7: Subir Código y Desplegar**
```bash
# Subir archivos de la aplicación
scp -i ofertaya-key.pem -r . ubuntu@$PUBLIC_IP:~/ofertaya-app

# Desplegar con Docker Compose optimizado
ssh -i ofertaya-key.pem ubuntu@$PUBLIC_IP << 'EOF'
cd ~/ofertaya-app
docker-compose -f docker-compose-aws-free.yml up -d
EOF
```

## 🔧 **Configuración Optimizada**

### **Archivo docker-compose-aws-free.yml**
Este archivo está optimizado para AWS Free Tier:
- ✅ **Una sola base de datos PostgreSQL** consolidada
- ✅ **Límites de memoria** (256MB por microservicio)
- ✅ **Límites de CPU** (0.5 cores por microservicio)
- ✅ **Sin Loki** (usa menos recursos)
- ✅ **Prometheus y Grafana ligeros**

### **Base de Datos Consolidada**
- **Un solo PostgreSQL** con múltiples esquemas
- **Menos uso de EBS** (solo 20 GB)
- **Mejor rendimiento** en t2.micro

## 📊 **Monitoreo de Recursos**

### **Verificar Uso de Recursos**
```bash
# Conectar a la instancia
ssh -i ofertaya-key.pem ubuntu@$PUBLIC_IP

# Verificar uso de memoria
free -h

# Verificar uso de CPU
htop

# Verificar uso de disco
df -h

# Verificar contenedores
docker stats
```

### **Límites Recomendados**
- **Memoria total**: Máximo 800MB (de 1GB disponible)
- **CPU**: Máximo 80% de uso
- **Disco**: Máximo 25GB (de 30GB gratis)

## 🌐 **Acceso a la Aplicación**

Una vez desplegada, podrás acceder a:

- **API Gateway**: `http://$PUBLIC_IP:8080`
- **Grafana**: `http://$PUBLIC_IP:3001` (admin/admin)
- **Prometheus**: `http://$PUBLIC_IP:9090`
- **Eureka**: `http://$PUBLIC_IP:8761`

## 💰 **Control de Costos**

### **Monitoreo de Facturación**
```bash
# Verificar uso actual
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### **Alertas de Costos**
- Configurar alertas en AWS Billing
- Límite recomendado: $5/mes
- Notificaciones por email

## 🔒 **Seguridad**

### **Configuraciones de Seguridad**
- ✅ **Security Group** con puertos mínimos
- ✅ **Key Pair** para SSH
- ✅ **Usuario no-root** (ubuntu)
- ✅ **Docker** sin privilegios elevados

### **Backup**
```bash
# Backup de la base de datos
ssh -i ofertaya-key.pem ubuntu@$PUBLIC_IP << 'EOF'
docker exec ofertaya_postgres pg_dump -U postgres ofertaya_consolidated > backup.sql
EOF

# Descargar backup
scp -i ofertaya-key.pem ubuntu@$PUBLIC_IP:~/backup.sql .
```

## 🚨 **Solución de Problemas**

### **Problemas Comunes**

1. **Instancia no responde**
```bash
# Reiniciar instancia
aws ec2 reboot-instances --instance-ids $INSTANCE_ID
```

2. **Docker sin memoria**
```bash
# Limpiar contenedores no usados
docker system prune -f
```

3. **Base de datos lenta**
```bash
# Optimizar PostgreSQL
docker exec ofertaya_postgres psql -U postgres -c "VACUUM ANALYZE;"
```

## 📈 **Escalabilidad Futura**

### **Cuando superes el Free Tier:**
1. **Migrar a t3.small** ($15/mes)
2. **Agregar RDS** ($25/mes)
3. **Implementar Load Balancer** ($18/mes)
4. **Usar EKS** para mejor orquestación

### **Migración Gradual:**
```bash
# Crear AMI de la instancia actual
aws ec2 create-image --instance-id $INSTANCE_ID --name "OfertaYa-Backup"

# Usar AMI para crear instancia más grande
aws ec2 run-instances --image-id ami-xxxxx --instance-type t3.small
```

## 🎯 **Resumen**

### **✅ Ventajas del Free Tier:**
- **Gratis por 12 meses**
- **Suficiente para desarrollo/MVP**
- **Fácil de configurar**
- **Escalable en el futuro**

### **⚠️ Limitaciones:**
- **Recursos limitados** (1GB RAM, 1 vCPU)
- **Sin alta disponibilidad**
- **Sin backup automático**
- **Sin Load Balancer**

### **🚀 Próximos Pasos:**
1. **Desplegar en Free Tier**
2. **Probar la aplicación**
3. **Monitorear recursos**
4. **Optimizar según necesidad**
5. **Migrar a plan de pago cuando sea necesario**

¿Te gustaría que te ayude con algún paso específico del despliegue? 