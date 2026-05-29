#!/bin/bash
# Worker — Amazon Linux 2023. MONGO_URI y RABBITMQ_HOST inyectados por Terraform.
set -euo pipefail
exec > >(tee /var/log/user-data-install-worker.log | logger -t user-data -s 2>/dev/console) 2>&1

sudo dnf update -y
sudo dnf install -y python3 python3-pip git

sleep 60

cd /home/ec2-user
rm -rf restaurant-api
git clone --depth 1 "${git_repo_url}" restaurant-api
cd restaurant-api

pip3 install --user -r requirements.txt

export MONGO_URI="${mongo_uri}"
export RABBITMQ_HOST="${rabbit_private_ip}"
export RABBITMQ_PORT=5672
export RABBITMQ_USER=admin
export RABBITMQ_PASSWORD=password123

pkill -f 'python3 -m api.worker' 2>/dev/null || true
nohup python3 -m api.worker > /var/log/worker.log 2>&1 &

echo "[install_worker] Worker iniciado; MONGO_URI=${mongo_uri} Rabbit=${rabbit_private_ip}" >> /var/log/worker_setup.log
