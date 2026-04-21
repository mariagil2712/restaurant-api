# =============================================================================
# Guía rápida: símbolos y sintaxis que verás en este archivo (Terraform / HCL)
# =============================================================================
#
# [Corchetes cuadrados] `[` `]`
#   - Delimitan una LISTA de valores, separados por comas.
#   - Ejemplo: cidr_blocks = ["0.0.0.0/0"]  →  una sola entrada CIDR.
#   - Ejemplo: security_groups = [aws_security_group.alb_sg.id]
#              →  lista con un ID de Security Group (referencia a otro recurso).
#
# [Llaves] `{` `}`
#   - Agrupan un BLOQUE de atributos o bloques anidados (ingress, egress, tags).
#   - Tras `resource "tipo" "nombre" {` todo lo que va entre llaves pertenece a ese recurso.
#
# [Comillas dobles] `"` `"`  (y a veces comillas simples en scripts, aquí casi todo va entre `"`)
#   - Encierran CADENAS de texto: nombres, descripciones, protocolos ("tcp"), etc.
#
# [Signo igual] `=`
#   - Asigna un valor a un atributo: nombre_atributo = valor
#
# [Punto] `.`  en referencias entre recursos
#   - Une el tipo lógico de Terraform, el nombre local del recurso y un atributo.
#   - Ejemplo: aws_security_group.alb_sg.id
#       · aws_security_group  →  tipo de recurso (bloque resource "aws_security_group" ...).
#       · alb_sg              →  segundo string del resource ("nombre local" en Terraform).
#       · id                  →  atributo devuelto por AWS (ID del security group).
#   - Así se dice: "usa el ID del SG que Terraform llama alb_sg".
#
# [Almohadilla] `#`
#   - Inicia un COMENTARIO: texto para humanos; Terraform lo ignora al planificar.
#
# [Guión en protocolo] `-1`
#   - En egress, protocol = "-1" significa "todos los protocolos" (tráfico de salida amplio).
#
# [CIDR] como 0.0.0.0/0
#   - Red en notación IP + máscara; 0.0.0.0/0 = cualquier dirección IPv4 (toda Internet).
#
# =============================================================================

# ==========================================
# Security Group: Application Load Balancer
# ==========================================
# Punto de entrada público HTTP hacia el ALB (no hacia la EC2 de la API directamente).
resource "aws_security_group" "alb_sg" {                # Crea SG del Application Load Balancer (fuente: AWS Security Groups + Terraform aws_security_group)
  name        = "restaurant_api_alb_sg"                 # Nombre visible del SG en consola AWS (fuente: atributo name del recurso)
  description = "HTTP publico hacia el ALB (puerto 80)" # Describe objetivo del grupo de seguridad (fuente: convención operacional)
  vpc_id      = var.vpc_id                              # Asocia SG a la VPC declarada en variables (fuente: requisito AWS VPC)

  ingress {                                                  # Regla de entrada permitida hacia ALB (fuente: AWS SG ingress rules)
    description = "HTTP desde Internet hacia el balanceador" # Etiqueta humana de la regla (fuente: buenas prácticas AWS)
    from_port   = 80                                         # Puerto inicial HTTP (fuente: estándar IANA HTTP)
    to_port     = 80                                         # Puerto final HTTP (fuente: estándar IANA HTTP)
    protocol    = "tcp"                                      # Protocolo de transporte de HTTP/1.1 en ALB listener (fuente: AWS ALB listener)
    cidr_blocks = ["0.0.0.0/0"]                              # Permite origen IPv4 global para endpoint público (fuente: CIDR AWS networking)
  }

  egress {                      # Regla de salida del SG del ALB (fuente: AWS SG egress model)
    from_port   = 0             # Inicio de rango cuando se permite todo (fuente: AWS SG docs)
    to_port     = 0             # Fin de rango ignorado al usar protocolo -1 (fuente: AWS SG docs)
    protocol    = "-1"          # Permite todos los protocolos de salida (fuente: AWS SG protocol values)
    cidr_blocks = ["0.0.0.0/0"] # Destinos IPv4 sin restricción (fuente: CIDR 0.0.0.0/0)
  }

  tags = {                         # Metadatos para clasificación de recursos (fuente: AWS resource tagging)
    Name = "restaurant-api-alb-sg" # Tag Name usado por consola y operaciones (fuente: convención AWS)
  }
}

# ==========================================
# Security Group: RabbitMQ
# ==========================================
# AMQP y management solo desde API y Worker (no desde Internet).
resource "aws_security_group" "rabbitmq_sg" {                    # SG de RabbitMQ con acceso controlado por origen (fuente: arquitectura de red del proyecto)
  name        = "rabbitmq_sg"                                    # Nombre lógico del SG en AWS (fuente: atributo name)
  description = "SSH; AMQP y management solo desde API y Worker" # Resumen funcional del alcance (fuente: diseño de seguridad)
  vpc_id      = var.vpc_id                                       # Ubica el SG en la misma VPC de servicios (fuente: AWS VPC scoping)

  ingress {                     # Regla SSH administrativa (fuente: operación de instancias EC2)
    description = "SSH"         # Identificador textual de acceso remoto (fuente: convención)
    from_port   = 22            # Puerto estándar SSH (fuente: IANA SSH)
    to_port     = 22            # Puerto único para SSH (fuente: IANA SSH)
    protocol    = "tcp"         # SSH opera sobre TCP (fuente: RFC 4253)
    cidr_blocks = ["0.0.0.0/0"] # Permite administración desde cualquier IP (fuente: configuración actual del entorno)
  }

  ingress {                                                                           # Permite tráfico AMQP hacia broker (fuente: RabbitMQ networking)
    description     = "RabbitMQ AMQP"                                                 # Etiqueta de la regla de mensajería (fuente: convención operacional)
    from_port       = 5672                                                            # Puerto AMQP predeterminado (fuente: RabbitMQ ports)
    to_port         = 5672                                                            # Rango cerrado para un solo puerto (fuente: AWS SG rule format)
    protocol        = "tcp"                                                           # AMQP usa TCP (fuente: protocolo AMQP 0-9-1)
    security_groups = [aws_security_group.api_sg.id, aws_security_group.worker_sg.id] # Restringe origen a SG de API y Worker (fuente: SG-to-SG referencing AWS)
  }

  ingress {                                                                           # Acceso al panel de administración RabbitMQ (fuente: RabbitMQ management plugin)
    description     = "RabbitMQ Management UI"                                        # Nombre de regla para interfaz web (fuente: operación RabbitMQ)
    from_port       = 15672                                                           # Puerto del management UI (fuente: RabbitMQ ports)
    to_port         = 15672                                                           # Apertura exacta del puerto web de gestión (fuente: AWS SG rule format)
    protocol        = "tcp"                                                           # Tráfico HTTP del panel sobre TCP (fuente: HTTP transport)
    security_groups = [aws_security_group.api_sg.id, aws_security_group.worker_sg.id] # Solo API/Worker pueden acceder según diseño (fuente: política interna del proyecto)
  }

  egress {                      # Salida libre para actualizaciones y respuestas (fuente: AWS SG default egress practice)
    from_port   = 0             # Inicio de rango para regla global (fuente: AWS SG docs)
    to_port     = 0             # Fin de rango para protocolo -1 (fuente: AWS SG docs)
    protocol    = "-1"          # Habilita todos los protocolos salientes (fuente: AWS protocol selector)
    cidr_blocks = ["0.0.0.0/0"] # Destino sin restricción IPv4 (fuente: CIDR)
  }

  tags = {               # Etiquetas del SG RabbitMQ (fuente: AWS tags best practices)
    Name = "rabbitmq_sg" # Nombre amigable del recurso (fuente: convención del proyecto)
  }
}

# ==========================================
# Security Group: Docker / REST API (detras del ALB)
# ==========================================
# La app (uvicorn) escucha en 8000; el ALB escucha en 80 y reenvia al target group :8000.
# Solo el SG del ALB debe poder llegar al puerto 8000 de la instancia API.
resource "aws_security_group" "api_sg" {                                                         # SG para instancias backend API (fuente: diseño ALB -> target)
  name        = "api_sg"                                                                         # Nombre del grupo en AWS (fuente: atributo name)
  description = "SSH; puerto 8000 solo desde el ALB (Swagger /docs va por el mismo puerto HTTP)" # Resume política de acceso a API (fuente: arquitectura de aplicación)
  vpc_id      = var.vpc_id                                                                       # Mantiene coherencia de red en la VPC definida (fuente: AWS VPC scoping)

  ingress {                     # SSH administrativo para la instancia API (fuente: operación EC2)
    description = "SSH"         # Etiqueta descriptiva de la regla (fuente: convención)
    from_port   = 22            # Puerto estándar de administración remota (fuente: IANA SSH)
    to_port     = 22            # Sin rango, solo puerto 22 (fuente: AWS SG rule format)
    protocol    = "tcp"         # SSH requiere TCP (fuente: RFC SSH)
    cidr_blocks = ["0.0.0.0/0"] # Acceso abierto según configuración actual del entorno (fuente: estado actual del proyecto)
  }

  ingress {                                                                         # Tráfico de aplicación desde el ALB a la API (fuente: AWS ALB target connectivity)
    description     = "API HTTP desde el ALB hacia la instancia (target port 8000)" # Contexto de la regla backend (fuente: diseño de balanceo)
    from_port       = 8000                                                          # Puerto donde escucha FastAPI/uvicorn (fuente: configuración de contenedor)
    to_port         = 8000                                                          # Puerto único para backend HTTP interno (fuente: arquitectura del proyecto)
    protocol        = "tcp"                                                         # Transporte de HTTP backend (fuente: TCP/IP)
    security_groups = [aws_security_group.alb_sg.id]                                # Solo tráfico proveniente del SG del ALB (fuente: principio de mínimo privilegio)
  }

  egress {                      # Salida abierta para dependencias externas (fuente: operación de aplicaciones)
    from_port   = 0             # Inicio de rango global (fuente: AWS SG docs)
    to_port     = 0             # Fin de rango global (fuente: AWS SG docs)
    protocol    = "-1"          # Todos los protocolos salientes (fuente: AWS SG protocol wildcard)
    cidr_blocks = ["0.0.0.0/0"] # Hacia cualquier red IPv4 (fuente: CIDR)
  }

  tags = {          # Tags para identificar SG de API (fuente: AWS tagging)
    Name = "api_sg" # Nombre lógico usado por equipo/curso (fuente: convención del proyecto)
  }
}

# ==========================================
# Security Group: Async Worker
# ==========================================
resource "aws_security_group" "worker_sg" {                                              # SG del proceso asíncrono worker (fuente: arquitectura de microservicios)
  name        = "worker_sg"                                                              # Nombre visible en consola AWS (fuente: atributo name)
  description = "SSH; el worker solo abre conexiones salientes hacia RabbitMQ/Mongo/SSM" # Resume comportamiento de red esperado (fuente: diseño del proyecto)
  vpc_id      = var.vpc_id                                                               # Asociación a la VPC del despliegue (fuente: AWS VPC requirements)

  ingress {                     # Entrada SSH para administración (fuente: operación EC2)
    description = "SSH"         # Etiqueta de regla de acceso remoto (fuente: convención)
    from_port   = 22            # Puerto SSH (fuente: IANA)
    to_port     = 22            # Rango único para SSH (fuente: AWS SG syntax)
    protocol    = "tcp"         # Protocolo requerido por SSH (fuente: RFC SSH)
    cidr_blocks = ["0.0.0.0/0"] # Acceso abierto según entorno de laboratorio (fuente: configuración actual)
  }

  egress {                      # El worker necesita salida para dependencias y actualizaciones (fuente: patrón app outbound)
    from_port   = 0             # Inicio de rango global de salida (fuente: AWS SG docs)
    to_port     = 0             # Fin de rango global de salida (fuente: AWS SG docs)
    protocol    = "-1"          # Cubre cualquier protocolo saliente (fuente: AWS SG protocol wildcard)
    cidr_blocks = ["0.0.0.0/0"] # Permite destinos IPv4 globales (fuente: CIDR)
  }

  tags = {             # Etiquetas para tracking del SG Worker (fuente: AWS tags)
    Name = "worker_sg" # Identificador visual del recurso (fuente: convención del proyecto)
  }
}

# ==========================================
# Security Group: PostgreSQL
# ==========================================
# Puerto 5432 solo desde API y Worker (plantilla de curso; restaurant-api puede no usar Postgres).
resource "aws_security_group" "postgres_sg" {             # SG para servicio PostgreSQL (fuente: AWS database network hardening)
  name        = "postgres_sg"                             # Nombre en AWS del SG de base de datos (fuente: atributo name)
  description = "SSH; PostgreSQL solo desde API y Worker" # Política de acceso a puerto DB (fuente: diseño interno)
  vpc_id      = var.vpc_id                                # SG dentro de VPC principal (fuente: AWS VPC scoping)

  ingress {                     # Acceso SSH administrativo al host PostgreSQL (fuente: operación EC2)
    description = "SSH"         # Etiqueta descriptiva de la regla (fuente: convención)
    from_port   = 22            # Puerto SSH estándar (fuente: IANA)
    to_port     = 22            # Puerto único de administración (fuente: AWS SG format)
    protocol    = "tcp"         # Transporte de SSH (fuente: RFC SSH)
    cidr_blocks = ["0.0.0.0/0"] # Permite administración remota sin restricción actual (fuente: configuración vigente)
  }

  ingress {                                                                           # Tráfico SQL interno solo desde servicios autorizados (fuente: PostgreSQL default port guidance)
    description     = "PostgreSQL"                                                    # Etiqueta de regla de base de datos (fuente: convención)
    from_port       = 5432                                                            # Puerto por defecto PostgreSQL (fuente: PostgreSQL docs)
    to_port         = 5432                                                            # Apertura exclusiva de puerto DB (fuente: AWS SG rules)
    protocol        = "tcp"                                                           # PostgreSQL usa TCP (fuente: PostgreSQL protocol)
    security_groups = [aws_security_group.api_sg.id, aws_security_group.worker_sg.id] # Limita origen a API y Worker (fuente: SG reference model AWS)
  }

  egress {                      # Salida general para actualizaciones y respuestas (fuente: operación host Linux)
    from_port   = 0             # Inicio rango global (fuente: AWS SG docs)
    to_port     = 0             # Fin rango global (fuente: AWS SG docs)
    protocol    = "-1"          # Todos los protocolos salientes (fuente: AWS SG protocol values)
    cidr_blocks = ["0.0.0.0/0"] # Hacia cualquier destino IPv4 (fuente: CIDR notation)
  }

  tags = {               # Tags de identificación de SG PostgreSQL (fuente: AWS tagging standards)
    Name = "postgres_sg" # Nombre amigable para operaciones (fuente: convención del proyecto)
  }
}

# ==========================================
# Security Group: MongoDB
# ==========================================
resource "aws_security_group" "mongodb_sg" {           # SG para instancia MongoDB del entorno (fuente: AWS SG best practices)
  name        = "mongodb_sg"                           # Nombre del grupo en la cuenta AWS (fuente: atributo name)
  description = "SSH; MongoDB solo desde API y Worker" # Resume política de puertos permitidos (fuente: diseño del proyecto)
  vpc_id      = var.vpc_id                             # Enlaza SG con la VPC del despliegue (fuente: AWS VPC scoping)

  ingress {                     # Regla SSH para administración de la instancia (fuente: operación EC2)
    description = "SSH"         # Identificador textual de la regla (fuente: convención)
    from_port   = 22            # Puerto estándar SSH (fuente: IANA)
    to_port     = 22            # Rango único SSH (fuente: AWS SG format)
    protocol    = "tcp"         # SSH utiliza TCP (fuente: RFC SSH)
    cidr_blocks = ["0.0.0.0/0"] # Permite acceso administrativo desde Internet (fuente: configuración actual)
  }

  ingress {                                                                           # Regla de base documental para clientes internos MongoDB (fuente: MongoDB default network port)
    description     = "MongoDB"                                                       # Nombre de la regla para puerto de base (fuente: convención)
    from_port       = 27017                                                           # Puerto predeterminado de MongoDB (fuente: MongoDB networking docs)
    to_port         = 27017                                                           # Solo abre puerto de servicio DB (fuente: AWS SG format)
    protocol        = "tcp"                                                           # Protocolo de transporte para MongoDB (fuente: MongoDB wire protocol over TCP)
    security_groups = [aws_security_group.api_sg.id, aws_security_group.worker_sg.id] # Autoriza únicamente API/Worker como origen (fuente: seguridad por SG)
  }

  egress {                      # Salida general requerida por sistema/paquetes (fuente: operación Linux en EC2)
    from_port   = 0             # Inicio de rango global (fuente: AWS SG docs)
    to_port     = 0             # Fin de rango global (fuente: AWS SG docs)
    protocol    = "-1"          # Cualquier protocolo en salida (fuente: AWS SG wildcard protocol)
    cidr_blocks = ["0.0.0.0/0"] # Permite destinos IPv4 sin limitar (fuente: CIDR)
  }

  tags = {              # Etiquetas de inventario para SG MongoDB (fuente: AWS tagging)
    Name = "mongodb_sg" # Nombre lógico usado en operaciones del proyecto (fuente: convención interna)
  }
}
