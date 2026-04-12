#!/bin/bash
# User data — API (Amazon Linux 2023), ALB target :8000
# IPs de RabbitMQ y Mongo inyectadas por Terraform (templatefile); no hace falta IAM ni SSM en la instancia.
# Credenciales: install_rabbitmq.sh (admin/password123) e install_mongodb.sh (admin/password123).
set -euo pipefail
exec > >(tee /var/log/user-data-install-api.log | logger -t user-data -s 2>/dev/console) 2>&1

sudo dnf update -y
sudo dnf install -y docker git

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user || true

# Tiempo para que RabbitMQ/Mongo terminen su user_data en las otras EC2
sleep 60

cd /home/ec2-user
rm -rf restaurant-api
git clone --depth 1 "${git_repo_url}" restaurant-api
cd restaurant-api

sudo docker build -t restaurant-api:latest .

sudo docker rm -f restaurant-api 2>/dev/null || true
sudo docker run -d --name restaurant-api --restart unless-stopped -p 8000:8000 \
  -e "RABBITMQ_HOST=${rabbit_private_ip}" \
  -e "RABBITMQ_PORT=5672" \
  -e "RABBITMQ_USER=admin" \
  -e "RABBITMQ_PASSWORD=password123" \
  -e "MONGO_URI=mongodb://admin:password123@${mongo_private_ip}:27017/?authSource=admin" \
  restaurant-api:latest

echo "[install_api] API en :8000; Rabbit=${rabbit_private_ip} Mongo=${mongo_private_ip}"
