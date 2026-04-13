#!/bin/bash
# Amazon Linux 2023 - Instalar dependencias y arrancar el Worker

set -euo pipefail
exec > >(tee /var/log/user-data-install-worker.log | logger -t user-data -s 2>/dev/console) 2>&1

sudo dnf update -y
sudo dnf install -y python3 python3-pip git

# Espera a que RabbitMQ y MongoDB terminen su arranque en sus respectivas EC2
sleep 60

# Clonar el repositorio del proyecto
cd /home/ec2-user
rm -rf restaurant-api
git clone --depth 1 "https://github.com/mariagil2712/restaurant-api.git" restaurant-api
cd restaurant-api

# Instalar dependencias del proyecto (incluyendo boto3 para Parameter Store)
pip3 install -r requirements.txt

# Arrancar el worker en segundo plano y guardar logs
nohup python3 worker.py > /var/log/worker.log 2>&1 &

echo "[install_worker] Worker iniciado a las $(date)" >> /var/log/worker_setup.log