# Salidas utiles tras terraform apply (DNS del ALB, IPs de diagnostico).

output "alb_dns_name" {                                                                        # Expone DNS público del balanceador al finalizar apply (fuente: Terraform Output Values)
  value       = aws_lb.api.dns_name                                                            # Referencia atributo dns_name del recurso aws_lb (fuente: AWS LB resource attributes)
  description = "DNS publico del ALB; URL base de la API y Swagger (ej. http://<valor>/docs )" # Documenta uso operativo de la salida (fuente: arquitectura del proyecto)
}

output "rabbitmq_public_ip" {                      # Muestra IP pública de instancia RabbitMQ (fuente: Terraform outputs para diagnóstico)
  value       = aws_instance.rabbitmq.public_ip    # Lee atributo public_ip de EC2 RabbitMQ (fuente: aws_instance attributes)
  description = "IP publica del servidor RabbitMQ" # Describe el dato devuelto (fuente: convención de salida)
}

output "api_public_ips" {                                                 # Expone lista de IPs de réplicas API para soporte (fuente: Terraform splat expressions)
  value       = aws_instance.api_server[*].public_ip                      # Recolecta public_ip de todas las instancias con count (fuente: HCL splat operator)
  description = "IPs publicas de las dos instancias API (detras del ALB)" # Aclara que tráfico productivo pasa por ALB (fuente: diseño de red)
}

output "worker_public_ip" {                      # Devuelve IP pública de instancia worker (fuente: Terraform output pattern)
  value       = aws_instance.worker.public_ip    # Referencia atributo generado por AWS EC2 (fuente: aws_instance attributes)
  description = "IP publica del servidor Worker" # Documentación breve para consumidores de output (fuente: convención del repo)
}

output "postgres_public_ip" {                        # Publica IP de la instancia PostgreSQL (fuente: Terraform outputs)
  value       = aws_instance.postgres.public_ip      # Obtiene public_ip de recurso postgres (fuente: aws_instance schema)
  description = "IP publica del servidor PostgreSQL" # Explica utilidad del output (fuente: operación del entorno)
}

output "mongodb_public_ip" {                      # Entrega IP pública de MongoDB para diagnóstico (fuente: Terraform outputs)
  value       = aws_instance.mongodb.public_ip    # Referencia atributo public_ip de la EC2 MongoDB (fuente: aws_instance attributes)
  description = "IP publica del servidor MongoDB" # Texto descriptivo para uso post-deploy (fuente: convención del proyecto)
}
