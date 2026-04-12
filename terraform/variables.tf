# Cloud computing AWS Variables

#Virtual Private Cloud personal iD (Juan Bustamante's account)
variable "vpc_id"{
    default = vpc-058e0cd8cb5cde2a1
}

#Amazon Machine Image iD
variable "ami_id" {
  default = "ami-02dfbd4ff395f2a1b" # Amazon Linux 2023
}

#AMI Instance type
variable "instance_type" {
  default = "t3.micro"
}

#Key pair name
variable "key_name" {
  default = "juanbustamante_u"
}

# 3 subnets in different zones inside the same region for higher availability
variable "subnets" {
  default = [
    "subnet-060ddd0dac60e2f5d", # us-east-1a
    "subnet-0c5c5ff530c2f5b1a", # us-east-1b
    "subnet-0662c505bccb76eb8"  # us-east-1c
  ]
}