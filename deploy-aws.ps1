# Script de PowerShell para desplegar OfertaYa en AWS Free Tier

Write-Host ">> Desplegando OfertaYa en AWS Free Tier..." -ForegroundColor Green

# --- Configuración ---
$region = "us-east-2"
$keyPairName = "ofertaya-key"
$keyFile = ".\\ofertaya-key.pem"
$instanceName = "OfertaYa-Server"
# AMI de Ubuntu 22.04 LTS para us-east-2 (Ohio), ID verificado por el usuario
$imageId = 'ami-085438ce84ab3ac76'
$instanceType = "t2.micro"
$securityGroupId = "sg-05edcf6bd3af9a484"
$subnetId = "subnet-0b07ad9aac330ba87"
$remoteUser = "ubuntu"
$remoteDir = "~/ofertaya-app"

# 1. Crear instancia EC2
Write-Host ">> Creando instancia EC2 '$instanceName'..." -ForegroundColor Cyan

$tagSpec = "ResourceType=instance,Tags=[{Key=Name,Value=$instanceName}]"
$awsArgs = @(
    "ec2",
    "run-instances",
    "--region", $region,
    "--image-id", $imageId,
    "--count", 1,
    "--instance-type", $instanceType,
    "--key-name", $keyPairName,
    "--security-group-ids", $securityGroupId,
    "--subnet-id", $subnetId,
    "--tag-specifications", $tagSpec
)
$instanceInfoJson = aws @awsArgs

If ($LASTEXITCODE -ne 0) { Write-Host ">> Error al crear la instancia EC2. Abortando." -ForegroundColor Red; exit 1 }

$instanceInfo = $instanceInfoJson | ConvertFrom-Json
$instanceId = $instanceInfo.Instances[0].InstanceId
Write-Host ">> Instancia creada con ID: $instanceId"

# 2. Esperar a que la instancia esté en ejecución y obtener su IP
Write-Host ">> Esperando a que la instancia esté en estado 'running'..." -ForegroundColor Yellow
aws ec2 wait instance-running --region $region --instance-ids $instanceId
Write-Host ">> Obteniendo IP pública..." -ForegroundColor Cyan
$ipAddress = (aws ec2 describe-instances --region $region --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicIpAddress' --output text).Trim()
Write-Host ">> IP Pública de la instancia: $ipAddress"

# 3. Pausa para que el servidor SSH se inicie
Write-Host ">> Esperando 30 segundos para que el servicio SSH esté disponible..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 4. Instalar Docker y Docker Compose en la instancia
Write-Host ">> Instalando Docker y Docker Compose..." -ForegroundColor Cyan
$sshTarget = "$($remoteUser)@$($ipAddress)"
$sshOptions = @(
    "-i", $keyFile,
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null"
)

$dockerInstallScript = @"
sudo apt-get update -y
sudo apt-get install -y docker.io 
sudo apt-get install -y docker-compose
sudo usermod -aG docker $remoteUser
sudo systemctl restart docker
"@
echo $dockerInstallScript | ssh.exe @sshOptions $sshTarget

# 5. Subir archivos de la aplicación a la instancia
Write-Host ">> Subiendo archivos de la aplicación (esto puede tardar)..." -ForegroundColor Cyan
ssh.exe @sshOptions $sshTarget "mkdir -p $remoteDir"

$scpTarget = "$($remoteUser)@$($ipAddress):$remoteDir"
$scpOptions = @(
    "-i", $keyFile,
    "-r",
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null"
)
# Usamos Get-ChildItem para pasar la lista de archivos a scp
Get-ChildItem -Path . | ForEach-Object { scp.exe @scpOptions $_.FullName $scpTarget }

If ($LASTEXITCODE -ne 0) { Write-Host ">> Error al copiar los archivos. Abortando." -ForegroundColor Red; exit 1 }

# 6. Desplegar la aplicación con Docker Compose
Write-Host ">> Iniciando servicios con Docker Compose..." -ForegroundColor Cyan
$deployScript = "cd $remoteDir; sudo docker-compose -f docker-compose-aws-free.yml up -d"
ssh.exe @sshOptions $sshTarget $deployScript

# 7. Mensaje final
Write-Host ">> Despliegue completado!" -ForegroundColor Green
Write-Host "Puedes acceder a los servicios en las siguientes URLs:"
Write-Host "--------------------------------------------------"
Write-Host "API Gateway: http://$ipAddress:8080"
Write-Host "Eureka: http://$ipAddress:8761"
Write-Host "Grafana: http://$ipAddress:3001"
Write-Host "Prometheus: http://$ipAddress:9090"
Write-Host "--------------------------------------------------" 