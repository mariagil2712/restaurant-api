# Salidas utiles tras terraform apply (DNS del ALB, IPs de diagnostico).

output "alb_dns_name" {
  value       = aws_lb.api.dns_name
  description = "DNS publico del ALB; URL base de la API y Swagger (ej. http://<valor>/docs )"
}

output "rabbitmq_public_ip" {
  value       = aws_instance.rabbitmq.public_ip
  description = "IP publica del servidor RabbitMQ"
}

output "api_public_ips" {
  value       = aws_instance.api_server[*].public_ip
  description = "IPs publicas de las dos instancias API (detras del ALB)"
}

output "worker_public_ip" {
  value       = aws_instance.worker.public_ip
  description = "IP publica del servidor Worker"
}

output "postgres_public_ip" {
  value       = aws_instance.postgres.public_ip
  description = "IP publica del servidor PostgreSQL"
}

output "mongodb_public_ip" {
  value       = aws_instance.mongodb.public_ip
  description = "IP publica del servidor MongoDB"
}
