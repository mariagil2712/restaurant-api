#!/bin/bash # Usa Bash para ejecutar script de arranque (fuente: GNU Bash manual)
# Amazon Linux 2023 - Instalar dependencias y arrancar el Worker

set -euo pipefail # Falla rápido ante errores, variables vacías y pipes rotos (fuente: buenas prácticas Bash)
exec > >(tee /var/log/user-data-install-worker.log | logger -t user-data -s 2>/dev/console) 2>&1 # Redirige stdout/stderr a archivo, syslog y consola EC2 (fuente: AWS user-data troubleshooting)

sudo dnf update -y # Actualiza índice y paquetes del sistema base (fuente: DNF docs)
sudo dnf install -y python3 python3-pip git # Instala runtime Python, pip y Git requeridos por el worker (fuente: dependencias del proyecto)

# Espera a que RabbitMQ y MongoDB terminen su arranque en sus respectivas EC2
sleep 60 # Espera infraestructura dependiente (Mongo/RabbitMQ) antes de iniciar worker (fuente: orden de arranque del proyecto)

# Clonar el repositorio del proyecto
cd /home/ec2-user # Usa home del usuario por defecto en Amazon Linux (fuente: convención EC2)
rm -rf restaurant-api # Limpia clon previo para evitar estado inconsistente (fuente: despliegue idempotente)
git clone --depth 1 "https://github.com/mariagil2712/restaurant-api.git" restaurant-api # Descarga solo último commit para acelerar bootstrap (fuente: Git shallow clone)
cd restaurant-api # Entra al directorio del código de la aplicación (fuente: estructura del repo)

# Instalar dependencias del proyecto (incluyendo boto3 para Parameter Store)
pip3 install -r requirements.txt # Instala dependencias Python declaradas por el proyecto (fuente: estándar pip requirements)

# Arrancar el worker en segundo plano y guardar logs
nohup python3 worker.py > /var/log/worker.log 2>&1 & # Ejecuta worker en background y persiste logs (fuente: utilidades nohup/shell)

echo "[install_worker] Worker iniciado a las $(date)" >> /var/log/worker_setup.log # Registra timestamp de inicio para soporte operativo (fuente: logging operativo)