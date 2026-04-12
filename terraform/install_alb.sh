#!/bin/bash
# Actualizar sistema e instalar Apache
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Obtener los metadatos de la instancia usando IMDSv2
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
HOSTNAME=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-hostname`
AZ=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
