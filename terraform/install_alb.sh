#!/bin/bash # Usa Bash para ejecutar user_data de EC2 (fuente: GNU Bash manual)
# Actualizar sistema e instalar Apache
yum update -y # Actualiza paquetes base del sistema (fuente: YUM docs para Amazon Linux)
yum install -y httpd # Instala Apache HTTP Server (fuente: paquetes oficiales Amazon Linux)
systemctl start httpd # Inicia servicio web Apache inmediatamente (fuente: systemctl start)
systemctl enable httpd # Habilita Apache al reiniciar la instancia (fuente: systemctl enable)

# Obtener los metadatos de la instancia usando IMDSv2
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` # Solicita token IMDSv2 con TTL de 6h (fuente: AWS EC2 Instance Metadata Service v2)
HOSTNAME=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-hostname` # Lee hostname interno de la instancia vía IMDS (fuente: AWS EC2 metadata paths)
AZ=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone` # Obtiene zona de disponibilidad para diagnóstico (fuente: AWS EC2 metadata placement)
