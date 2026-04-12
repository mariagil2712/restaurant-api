# =============================================================================
# main.tf — Arquitectura restaurant-api en AWS (IaC)
# =============================================================================
#
# Este archivo fusiona dos patrones del material de clase:
#
#   1) aws-iaas-rabbitmq-postgresql-mongodb-students/main.tf
#      - Varias instancias EC2 (RabbitMQ, API, Worker, Postgres, MongoDB).
#      - Parámetros SSM (Parameter Store) con IPs públicas para integración.
#
#   2) aws-iaas-alb/main.tf
#      - Application Load Balancer (ALB) con target group y listener HTTP.
#      - Varias instancias detrás del balanceador (aquí: 2 réplicas API).
#
# Flujo de tráfico hacia la API:
#   Cliente → ALB:80 → Target Group → instancia API:8000 (uvicorn / FastAPI).
#   La documentación Swagger suele consultarse en http://<DNS-ALB>/docs
#
# Requisitos de variables (variables.tf):
#   - var.subnets debe tener al menos 2 subnets en distintas AZ (el ALB lo exige).
#   - Las subnets deben pertenecer a var.vpc_id.
#
# Security groups (security_groups.tf):
#   - alb_sg  : entrada pública 80 hacia el ALB.
#   - api_sg  : puerto 8000 solo desde alb_sg hacia las instancias API.
#
# User data API: templatefile("install_api.tpl") inyecta IPs privadas de RabbitMQ
# y MongoDB (no se usa SSM desde la EC2; los parámetros SSM siguen existiendo para otros usos).
#
# =============================================================================

locals {
  api_user_data = templatefile("${path.module}/install_api.tpl", {
    rabbit_private_ip = aws_instance.rabbitmq.private_ip
    mongo_private_ip  = aws_instance.mongodb.private_ip
    git_repo_url      = var.git_repo_url
  })
}

# -----------------------------------------------------------------------------
# Sección 1 — Instancias de soporte (una por servicio)
# -----------------------------------------------------------------------------
# Cada recurso "aws_instance" crea una máquina virtual. Todas usan la primera
# subnet de la lista para simplificar (tráfico interno entre servicios en VPC).

resource "aws_instance" "rabbitmq" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnets[0]
  vpc_security_group_ids      = [aws_security_group.rabbitmq_sg.id]
  user_data                   = file("${path.module}/install_rabbitmq.sh")
  associate_public_ip_address = true

  tags = {
    Name = "restaurant-api-RabbitMQ"
    Role = "MessageBroker"
  }
}

resource "aws_instance" "worker" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnets[0]
  vpc_security_group_ids      = [aws_security_group.worker_sg.id]
  user_data                   = file("${path.module}/install_worker.sh")
  associate_public_ip_address = true

  tags = {
    Name = "restaurant-api-Worker"
    Role = "AsyncWorker"
  }
}

resource "aws_instance" "postgres" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnets[0]
  vpc_security_group_ids      = [aws_security_group.postgres_sg.id]
  user_data                   = file("${path.module}/install_postgres.sh")
  associate_public_ip_address = true

  tags = {
    Name = "restaurant-api-Postgres"
    Role = "Database"
  }
}

resource "aws_instance" "mongodb" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnets[0]
  vpc_security_group_ids      = [aws_security_group.mongodb_sg.id]
  user_data                   = file("${path.module}/install_mongodb.sh")
  associate_public_ip_address = true

  tags = {
    Name = "restaurant-api-MongoDB"
    Role = "NoSQLDatabase"
  }
}

# -----------------------------------------------------------------------------
# Sección 2 — Instancias API (mínimo 2) para alta disponibilidad detrás del ALB
# -----------------------------------------------------------------------------
# count = 2 crea dos recursos: aws_instance.api_server[0] y [1].
# Cada una va en una subnet distinta (índices 0 y 1) para repartir AZs.

resource "aws_instance" "api_server" {
  count = 2

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnets[count.index]
  vpc_security_group_ids      = [aws_security_group.api_sg.id]
  user_data                   = local.api_user_data
  associate_public_ip_address = true

  tags = {
    Name = "restaurant-api-API-${count.index + 1}"
    Role = "BackendAPI"
  }
}

# -----------------------------------------------------------------------------
# Sección 3 — Target Group del ALB (puerto de aplicación 8000)
# -----------------------------------------------------------------------------
# El listener del ALB escucha en 80; el target group envía tráfico al puerto
# donde escucha la app en la instancia (8000). El health check usa GET / .

resource "aws_lb_target_group" "api" {
  name_prefix = "rapitg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "restaurant-api-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Adjuntar cada instancia API al target group en el puerto 8000.
resource "aws_lb_target_group_attachment" "api" {
  count            = 2
  target_group_arn = aws_lb_target_group.api.arn
  target_id        = aws_instance.api_server[count.index].id
  port             = 8000
}

# -----------------------------------------------------------------------------
# Sección 4 — Application Load Balancer y listener HTTP
# -----------------------------------------------------------------------------
# subnets: las dos primeras subnets en AZ distintas (requisito del ALB).
# security_groups: tráfico entrante al balanceador gestionado por alb_sg.

resource "aws_lb" "api" {
  name_prefix        = "rapalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = slice(var.subnets, 0, 2)

  tags = {
    Name = "restaurant-api-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# -----------------------------------------------------------------------------
# Sección 5 — AWS Systems Manager Parameter Store
# -----------------------------------------------------------------------------
# Publicamos IPs (y DNS del ALB) para que aplicaciones o scripts lean valores
# sin hardcodear (patrón del ejemplo rabbitmq-postgresql-mongodb-students).
# Rutas bajo /message-queue/dev/restaurant-api/ para no chocar con otros labs.

resource "aws_ssm_parameter" "rabbitmq_ip" {
  name        = "${var.ssm_parameter_prefix}/rabbitmq/public_ip"
  type        = "String"
  value       = aws_instance.rabbitmq.public_ip
  description = "IP publica del servidor RabbitMQ (restaurant-api)"
}

resource "aws_ssm_parameter" "api_alb_dns" {
  name        = "${var.ssm_parameter_prefix}/api/alb_dns_name"
  type        = "String"
  value       = aws_lb.api.dns_name
  description = "DNS publico del ALB; punto de entrada HTTP de la API (puerto 80)"
}

resource "aws_ssm_parameter" "api_instance_ips" {
  name        = "${var.ssm_parameter_prefix}/api/instance_public_ips"
  type        = "String"
  value       = join(",", aws_instance.api_server[*].public_ip)
  description = "IPs publicas de las instancias API (diagnostico; trafico de usuarios va al ALB)"
}

resource "aws_ssm_parameter" "worker_ip" {
  name        = "${var.ssm_parameter_prefix}/worker/public_ip"
  type        = "String"
  value       = aws_instance.worker.public_ip
  description = "IP publica del Worker (restaurant-api)"
}

resource "aws_ssm_parameter" "postgres_ip" {
  name        = "${var.ssm_parameter_prefix}/postgres/public_ip"
  type        = "String"
  value       = aws_instance.postgres.public_ip
  description = "IP publica del servidor PostgreSQL (restaurant-api)"
}

resource "aws_ssm_parameter" "mongodb_ip" {
  name        = "${var.ssm_parameter_prefix}/mongodb/public_ip"
  type        = "String"
  value       = aws_instance.mongodb.public_ip
  description = "IP publica del servidor MongoDB (restaurant-api)"
}
