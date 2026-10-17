variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used in resource names/tags"
  type        = string
  default     = "ecommerce"
}

variable "vpc_cidr" {
  description = "IP range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IP range for the public subnet (must be inside vpc_cidr)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 size. t3.small = 2 GB RAM (6 containers incl. MongoDB)"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the EC2 key pair created in the AWS console"
  type        = string
  default     = "ecommerce-key"
}

variable "dockerhub_username" {
  description = "Docker Hub account that hosts the images"
  type        = string
  default     = "rishav1994sonai"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "v1"
}

variable "my_ip_cidr" {
  description = "Your public IP (x.x.x.x/32) allowed to SSH and hit backend ports directly"
  type        = string
  default     = "0.0.0.0/0"
}

variable "jwt_secret" {
  description = "Secret used by user-service to sign login tokens"
  type        = string
  sensitive   = true
}
