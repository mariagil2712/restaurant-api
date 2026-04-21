# Cloud computing AWS — variables Terraform (restaurant-api)

# Virtual Private Cloud (ID de la VPC donde se despliegan SG, EC2 y ALB).
variable "vpc_id" {                     # Define variable de entrada para identificar la VPC de despliegue (fuente: Terraform Input Variables)
  type        = string                  # Restringe el tipo a texto (fuente: sistema de tipos HCL)
  description = "ID de la VPC"          # Documenta el propósito de la variable (fuente: convención Terraform)
  default     = "vpc-058e0cd8cb5cde2a1" # Valor por defecto del laboratorio/proyecto (fuente: configuración actual AWS)
}

# AMI Amazon Linux 2023 (x86_64) en la región de despliegue.
variable "ami_id" {                                    # Variable para AMI base de las EC2 (fuente: Terraform Input Variables)
  type        = string                                 # Tipo texto para IDs de AMI (fuente: formato IDs AWS)
  description = "ID de la AMI para las instancias EC2" # Describe uso de la variable (fuente: convención Terraform)
  default     = "ami-02dfbd4ff395f2a1b"                # AMI Amazon Linux 2023 usada en esta región (fuente: catálogo AMI AWS)
}

variable "instance_type" {              # Define familia/tamaño de instancia EC2 (fuente: Terraform variable pattern)
  type        = string                  # Tipo string para nombre de instancia (fuente: AWS EC2 instance types)
  description = "Tipo de instancia EC2" # Ayuda a entender el parámetro en plan/apply (fuente: convención Terraform)
  default     = "t3.micro"              # Valor por defecto económico para pruebas (fuente: elección del proyecto)
}

# Nombre del key pair en EC2 (misma región que el provider).
variable "key_name" {                          # Variable para key pair usado en acceso SSH (fuente: AWS EC2 key pairs)
  type        = string                         # Tipo string para nombre lógico del key pair (fuente: Terraform types)
  description = "Nombre del par de llaves EC2" # Documenta entrada requerida (fuente: convención Terraform)
  default     = "juanbustamante_u"             # Key pair por defecto del entorno actual (fuente: configuración del proyecto)
}

# Tres subnets en zonas distintas (el ALB usa al menos dos; ver main.tf slice).
variable "subnets" {                                                         # Lista de subnets para ubicar EC2 y ALB (fuente: AWS VPC subnet model)
  type        = list(string)                                                 # Lista de IDs en texto (fuente: tipos compuestos HCL)
  description = "Lista de subnet IDs (mínimo 2 en AZ distintas para el ALB)" # Requisito del ALB multi-AZ (fuente: AWS ALB docs)
  default = [
    "subnet-060ddd0dac60e2f5d", # Subnet en us-east-1a (fuente: inventario VPC actual)
    "subnet-0c5c5ff530c2f5b1a", # Subnet en us-east-1b (fuente: inventario VPC actual)
    "subnet-0662c505bccb76eb8", # Subnet en us-east-1c (fuente: inventario VPC actual)
  ]
}

# Debe coincidir con la región del provider en providers.tf (us-east-1).
variable "aws_region" {                                                   # Variable de región reutilizable en scripts/recursos (fuente: Terraform variable reuse)
  type        = string                                                    # Tipo texto para región AWS (fuente: nomenclatura regional AWS)
  description = "Región AWS (usada por install_api.sh con AWS CLI / SSM)" # Explica dependencia con scripts de bootstrap (fuente: diseño del proyecto)
  default     = "us-east-1"                                               # Región por defecto del despliegue (fuente: provider actual)
}

# Repo HTTPS clonado en la EC2 API (inyectado en install_api.tpl vía templatefile en main.tf).
variable "git_repo_url" {                                                # URL del repositorio que se clona en user_data (fuente: patrón bootstrap Git)
  type        = string                                                   # Tipo string para URL HTTPS (fuente: tipos HCL)
  description = "URL HTTPS del repositorio a clonar en la instancia API" # Documenta propósito de despliegue (fuente: convención Terraform)
  default     = "https://github.com/mariagil2712/restaurant-api.git"     # Repositorio backend configurado actualmente (fuente: repo del proyecto)
}

# Prefijo de parámetros SSM que publica main.tf (lectura opcional desde tu PC con AWS CLI; la EC2 API no lo usa).
variable "ssm_parameter_prefix" {                                                             # Prefijo base para nombres de parámetros SSM (fuente: AWS SSM naming conventions)
  type        = string                                                                        # Tipo texto porque SSM paths son strings (fuente: AWS SSM Parameter Store)
  description = "Prefijo Parameter Store (sin barra final) para aws_ssm_parameter en main.tf" # Aclara formato esperado del path (fuente: diseño main.tf)
  default     = "/message-queue/dev/restaurant-api"                                           # Namespace actual de parámetros del entorno dev (fuente: estructura del proyecto)
}
