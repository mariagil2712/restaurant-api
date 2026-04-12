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
resource "aws_security_group" "alb_sg" {
  name        = "restaurant_api_alb_sg"
  description = "HTTP publico hacia el ALB (puerto 80)"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP desde Internet hacia el balanceador"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "restaurant-api-alb-sg"
  }
}

# ==========================================
# Security Group: RabbitMQ
# ==========================================
# AMQP y management solo desde API y Worker (no desde Internet).
resource "aws_security_group" "rabbitmq_sg" {
  name        = "rabbitmq_sg"
  description = "SSH; AMQP y management solo desde API y Worker"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "RabbitMQ AMQP"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.api_sg.id, aws_security_group.worker_sg.id]
  }

  ingress {
    description     = "RabbitMQ Management UI"
    from_port       = 15672
    to_port         = 15672
    protocol        = "tcp"
    security_groups = [aws_security_group.api_sg.id, aws_security_group.worker_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rabbitmq_sg"
  }
}

# ==========================================
# Security Group: Docker / REST API (detras del ALB)
# ==========================================
# La app (uvicorn) escucha en 8000; el ALB escucha en 80 y reenvia al target group :8000.
# Solo el SG del ALB debe poder llegar al puerto 8000 de la instancia API.
resource "aws_security_group" "api_sg" {
  name        = "api_sg"
  description = "SSH; puerto 8000 solo desde el ALB (Swagger /docs va por el mismo puerto HTTP)"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "API HTTP desde el ALB hacia la instancia (target port 8000)"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "api_sg"
  }
}

# ==========================================
# Security Group: Async Worker
# ==========================================
resource "aws_security_group" "worker_sg" {
  name        = "worker_sg"
  description = "SSH; el worker solo abre conexiones salientes hacia RabbitMQ/Mongo/SSM"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "worker_sg"
  }
}

# ==========================================
# Security Group: PostgreSQL
# ==========================================
# Puerto 5432 solo desde API y Worker (plantilla de curso; restaurant-api puede no usar Postgres).
resource "aws_security_group" "postgres_sg" {
  name        = "postgres_sg"
  description = "SSH; PostgreSQL solo desde API y Worker"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api_sg.id, aws_security_group.worker_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "postgres_sg"
  }
}

# ==========================================
# Security Group: MongoDB
# ==========================================
resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb_sg"
  description = "SSH; MongoDB solo desde API y Worker"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "MongoDB"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.api_sg.id, aws_security_group.worker_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mongodb_sg"
  }
}
