#!/bin/bash # Usa Bash como intérprete de comandos (fuente: GNU Bash manual)
# Amazon Linux 2023 - Instalar PostgreSQL 15
sudo dnf update -y # Actualiza repos y paquetes del sistema (fuente: DNF docs)
sudo dnf install -y postgresql15-server # Instala PostgreSQL 15 server package (fuente: Amazon Linux package repos)

# Inicializar la base de datos
sudo postgresql-setup --initdb # Inicializa cluster de datos en /var/lib/pgsql/data (fuente: PostgreSQL RPM scripts)

# Configurar Postgres para aceptar conexiones externas
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf # Habilita escucha en todas las interfaces (fuente: PostgreSQL runtime config)

# Permitir conexiones IPv4 en pg_hba.conf para el bloque 0.0.0.0/0
echo "host    all             all             0.0.0.0/0               scram-sha-256" | sudo tee -a /var/lib/pgsql/data/pg_hba.conf # Agrega regla de autenticación remota con SCRAM (fuente: PostgreSQL pg_hba.conf docs)

# Habilitar y reiniciar Postgres
sudo systemctl enable postgresql # Habilita inicio automático del servicio (fuente: systemctl enable)
sudo systemctl start postgresql # Arranca servicio PostgreSQL en esta sesión (fuente: systemctl start)

# Crear base de datos y usuario de prueba
sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'password123';" # Crea rol de aplicación con contraseña (fuente: SQL CREATE USER)
sudo -u postgres psql -c "CREATE DATABASE mydb OWNER admin;" # Crea base de datos y asigna propietario (fuente: SQL CREATE DATABASE)
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mydb TO admin;" # Otorga permisos completos al rol en la base (fuente: SQL GRANT)
