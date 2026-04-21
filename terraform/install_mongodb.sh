#!/bin/bash # Usa Bash para ejecutar el user_data (fuente: GNU Bash manual)
# Amazon Linux 2023 - Instalar MongoDB 7.0 + Configuración de Admin

# 1. Agregar el repositorio oficial de MongoDB para Amazon Linux (CentOS/RHEL)
sudo bash -c 'cat <<EOF > /etc/yum.repos.d/mongodb-org-7.0.repo # Crea repo YUM oficial de MongoDB 7.0 (fuente: MongoDB Install on Amazon Linux)
[mongodb-org-7.0] # Define id del repositorio de paquetes (fuente: formato .repo de YUM/DNF)
name=MongoDB Repository # Nombre descriptivo mostrado por DNF (fuente: documentación DNF repos)
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/ # URL oficial de paquetes MongoDB para Amazon Linux 2023 (fuente: MongoDB repos)
gpgcheck=1 # Exige verificación de firma GPG del paquete (fuente: buenas prácticas YUM/DNF)
enabled=1 # Habilita este repositorio para instalación (fuente: sintaxis YUM/DNF)
gpgkey=https://pgp.mongodb.com/server-7.0.asc # Llave pública oficial para validar paquetes (fuente: MongoDB security docs)
EOF' # Cierra heredoc y escritura del archivo .repo (fuente: sintaxis Bash heredoc)

# 2. Instalación de MongoDB
sudo dnf install -y mongodb-org # Instala metapaquete oficial de MongoDB (fuente: MongoDB installation guide)

# 3. Configuración inicial de red (Bind IP)
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf # Permite conexiones remotas cambiando bindIp (fuente: MongoDB networking docs)

# 4. Iniciar servicio
sudo systemctl daemon-reload # Recarga definición de unidades systemd (fuente: systemd man pages)
sudo systemctl enable mongod # Habilita arranque automático del servicio mongod (fuente: systemctl enable)
sudo systemctl start mongod # Inicia MongoDB inmediatamente (fuente: systemctl start)

# 5. Esperar a que MongoDB esté listo para recibir comandos
until sudo mongosh --eval "db.adminCommand('ping')" &>/dev/null; do # Espera activa hasta que Mongo responda ping (fuente: MongoDB adminCommand)
  echo "Esperando a MongoDB..." # Log temporal mientras el servicio termina de levantar (fuente: práctica operativa)
  sleep 2 # Reintento cada 2 segundos para no saturar CPU (fuente: patrón retry/backoff básico)
done # Finaliza bucle cuando ping responde correctamente (fuente: sintaxis Bash)

# 6. Crear usuario administrador ##PENDIENTE DE CAMBIAR PASSWORD Y USERNAME
sudo mongosh admin --eval " # Ejecuta JavaScript en DB admin para crear usuario (fuente: MongoDB createUser docs)
  db.createUser({ # Crea usuario autenticable en MongoDB (fuente: MongoDB security docs)
    user: 'admin', # Nombre del usuario administrador inicial (fuente: decisión del proyecto)
    pwd: 'password123', # Contraseña inicial temporal del proyecto (fuente: configuración actual del repo)
    roles: [ { role: 'userAdminAnyDatabase', db: 'admin' }, 'readWriteAnyDatabase' ] # Permisos administrativos y lectura/escritura global (fuente: catálogo de roles MongoDB)
  }) # Cierre del objeto de creación de usuario (fuente: sintaxis JavaScript en mongosh)
" # Cierra script inline enviado a mongosh (fuente: sintaxis Bash string)

# 7. Activar la autenticación en el archivo de configuración
cat <<EOF >> /etc/mongod.conf # Agrega bloque de seguridad al final del archivo de configuración (fuente: MongoDB security docs)
security: # Sección de seguridad de mongod.conf (fuente: estructura de configuración MongoDB)
  authorization: enabled # Activa autenticación obligatoria para operaciones (fuente: MongoDB authorization)
EOF # Cierra heredoc de configuración de MongoDB (fuente: sintaxis Bash heredoc)

# 8. Reiniciar para aplicar seguridad
sudo systemctl restart mongod # Reinicia para aplicar cambios de autenticación (fuente: operación estándar systemd)

echo "MongoDB instalado y securizado con usuario 'admin' a las $(date)" >> /var/log/mongodb_setup.log # Guarda evidencia de instalación en log local (fuente: observabilidad básica)
