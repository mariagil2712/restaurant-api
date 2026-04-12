# Cloud computing AWS — variables Terraform (restaurant-api)

# Virtual Private Cloud (ID de la VPC donde se despliegan SG, EC2 y ALB).
variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
  default     = "vpc-058e0cd8cb5cde2a1"
}

# AMI Amazon Linux 2023 (x86_64) en la región de despliegue.
variable "ami_id" {
  type        = string
  description = "ID de la AMI para las instancias EC2"
  default     = "ami-02dfbd4ff395f2a1b"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2"
  default     = "t3.micro"
}

# Nombre del key pair en EC2 (misma región que el provider).
variable "key_name" {
  type        = string
  description = "Nombre del par de llaves EC2"
  default     = "juanbustamante_u"
}

# Tres subnets en zonas distintas (el ALB usa al menos dos; ver main.tf slice).
variable "subnets" {
  type        = list(string)
  description = "Lista de subnet IDs (mínimo 2 en AZ distintas para el ALB)"
  default = [
    "subnet-060ddd0dac60e2f5d", # us-east-1a
    "subnet-0c5c5ff530c2f5b1a", # us-east-1b
    "subnet-0662c505bccb76eb8", # us-east-1c
  ]
}

# Debe coincidir con la región del provider en providers.tf (us-east-1).
variable "aws_region" {
  type        = string
  description = "Región AWS (usada por install_api.sh con AWS CLI / SSM)"
  default     = "us-east-1"
}

# Repo HTTPS clonado en la EC2 API (inyectado en install_api.tpl vía templatefile en main.tf).
variable "git_repo_url" {
  type        = string
  description = "URL HTTPS del repositorio a clonar en la instancia API"
  default     = "https://github.com/mariagil2712/restaurant-api.git"
}

# Prefijo de parámetros SSM que publica main.tf (lectura opcional desde tu PC con AWS CLI; la EC2 API no lo usa).
variable "ssm_parameter_prefix" {
  type        = string
  description = "Prefijo Parameter Store (sin barra final) para aws_ssm_parameter en main.tf"
  default     = "/message-queue/dev/restaurant-api"
}
