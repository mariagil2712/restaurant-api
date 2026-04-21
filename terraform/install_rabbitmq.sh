#!/bin/bash # Usa Bash para el aprovisionamiento inicial (fuente: GNU Bash manual)
# Amazon Linux 2023 - Instalar Docker y RabbitMQ via Docker Compose

# 1. Update system and install Docker
sudo dnf update -y # Actualiza paquetes y metadatos del sistema (fuente: DNF docs)
sudo dnf install -y docker # Instala Docker Engine desde repos oficiales (fuente: Amazon Linux packages)

# 2. Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose # Descarga binario Docker Compose para SO/arquitectura actual (fuente: Docker Compose releases)
sudo chmod +x /usr/local/bin/docker-compose # Da permisos de ejecución al binario descargado (fuente: chmod manual)

# 3. Enable and start Docker
sudo systemctl enable docker # Habilita Docker al arranque del sistema (fuente: systemctl enable)
sudo systemctl start docker # Inicia daemon Docker en esta sesión (fuente: systemctl start)
sudo usermod -aG docker ec2-user # Permite a ec2-user usar Docker sin sudo en futuras sesiones (fuente: Docker post-install docs)

# 4. Create directory for RabbitMQ
mkdir -p /home/ec2-user/rabbitmq # Crea carpeta de despliegue para compose de RabbitMQ (fuente: organización local del proyecto)
cd /home/ec2-user/rabbitmq # Entra al directorio donde se generará docker-compose.yml (fuente: flujo del script)

# 5. Create docker-compose.yml
cat << 'EOF' > docker-compose.yml # Escribe archivo compose inline con heredoc (fuente: sintaxis Bash heredoc)
services: # Define servicios del stack Docker Compose (fuente: Compose specification)
  rabbitmq: # Servicio único para broker RabbitMQ (fuente: arquitectura del proyecto)
    image: rabbitmq:3-management # Usa imagen oficial con plugin de management habilitado (fuente: Docker Hub RabbitMQ)
    container_name: rabbitmq_server # Nombre fijo para facilitar administración local (fuente: convención del proyecto)
    ports: # Publica puertos del contenedor hacia la instancia (fuente: Compose networking)
      - "5672:5672" # Puerto AMQP de RabbitMQ para productores/consumidores (fuente: RabbitMQ networking docs)
      - "15672:15672" # Puerto de panel web de administración (fuente: RabbitMQ management plugin)
    environment: # Variables de entorno consumidas por imagen oficial RabbitMQ (fuente: Docker Hub RabbitMQ env vars)
      RABBITMQ_DEFAULT_USER: admin # Usuario inicial del broker (fuente: configuración actual del proyecto)
      RABBITMQ_DEFAULT_PASS: password123 # Password inicial del broker (fuente: configuración actual del proyecto)
    healthcheck: # Verificación periódica de salud del contenedor (fuente: Docker Compose healthcheck)
      test: [ "CMD", "rabbitmq-diagnostics", "-q", "ping" ] # Confirma que el nodo responde internamente (fuente: RabbitMQ diagnostics)
      interval: 10s # Frecuencia entre chequeos de salud (fuente: Compose healthcheck options)
      timeout: 5s # Tiempo máximo para cada chequeo (fuente: Compose healthcheck options)
      retries: 5 # Cantidad de fallos consecutivos antes de marcar unhealthy (fuente: Compose healthcheck options)
EOF # Cierra heredoc y guarda el docker-compose.yml (fuente: sintaxis Bash heredoc)

# Asignar permisos al usuario ec2-user
chown -R ec2-user:ec2-user /home/ec2-user/rabbitmq # Ajusta propietario para gestión por ec2-user (fuente: Linux file ownership)

# 6. Start RabbitMQ container
sudo docker-compose up -d # Levanta RabbitMQ en modo detached (fuente: Docker Compose command reference)

