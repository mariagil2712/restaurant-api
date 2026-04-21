#!/bin/bash # Usa Bash para user_data de API (fuente: GNU Bash manual)
# =============================================================================
# NOTA: el user_data de las instancias API lo genera Terraform con install_api.tpl
# (templatefile en main.tf), inyectando IPs privadas de RabbitMQ y MongoDB.
# Este .sh se mantiene como referencia del mismo arranque sin plantilla (p. ej. pruebas locales).
# =============================================================================
set -euo pipefail # Activa modo estricto para evitar fallos silenciosos (fuente: buenas prácticas Bash)
exec > >(tee /var/log/user-data-install-api.log | logger -t user-data -s 2>/dev/console) 2>&1 # Envía logs a archivo, syslog y consola EC2 (fuente: AWS user-data debug guide)

sudo dnf update -y # Actualiza paquetes del sistema base (fuente: DNF docs)
sudo dnf install -y docker git # Instala Docker para contenedor y Git para clonar repo (fuente: requerimientos de despliegue)

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose # Descarga Docker Compose según SO/arquitectura (fuente: Docker Compose releases)
sudo chmod +x /usr/local/bin/docker-compose # Marca binario como ejecutable (fuente: chmod manual)

sudo systemctl enable docker # Habilita Docker en cada reinicio (fuente: systemctl enable)
sudo systemctl start docker # Inicia daemon Docker inmediatamente (fuente: systemctl start)
sudo usermod -aG docker ec2-user || true # Agrega ec2-user al grupo docker y evita fallo si ya está (fuente: Docker post-install + control de errores Bash)

sleep 60 # Espera a que servicios dependientes terminen de arrancar (fuente: orden de despliegue entre instancias)

# Sustituir manualmente si ejecutas este script fuera de Terraform:
GIT_REPO_URL="${GIT_REPO_URL:-https://github.com/mariagil2712/restaurant-api.git}" # Usa variable externa o URL por defecto del repo (fuente: expansión de parámetros Bash)
RABBIT_IP="${RABBIT_IP:-localhost}" # Define host de RabbitMQ con fallback local (fuente: expansión de parámetros Bash)
MONGO_IP="${MONGO_IP:-localhost}" # Define host de MongoDB con fallback local (fuente: expansión de parámetros Bash)

cd /home/ec2-user # Trabaja en home del usuario estándar de EC2 (fuente: convención Amazon Linux)
rm -rf restaurant-api # Elimina clon previo para despliegue idempotente (fuente: práctica de bootstrap)
git clone --depth 1 "$GIT_REPO_URL" restaurant-api # Clona únicamente el último commit para acelerar descarga (fuente: Git shallow clone)
cd restaurant-api # Entra al código fuente para construir imagen (fuente: estructura del repositorio)

sudo docker build -t restaurant-api:latest . # Construye imagen local de la API con tag latest (fuente: Docker build docs)

sudo docker rm -f restaurant-api 2>/dev/null || true # Remueve contenedor previo si existe, sin detener el script en error (fuente: Docker rm + Bash tolerante)
sudo docker run -d --name restaurant-api --restart unless-stopped -p 8000:8000 -e "RABBITMQ_HOST=$RABBIT_IP" -e "RABBITMQ_PORT=5672" -e "RABBITMQ_USER=admin" -e "RABBITMQ_PASSWORD=password123" -e "MONGO_URI=mongodb://admin:password123@${MONGO_IP}:27017/?authSource=admin" restaurant-api:latest # Inicia API publicando :8000 y pasando variables de conexión a Rabbit/Mongo (fuente: Docker run + variables de la app)
