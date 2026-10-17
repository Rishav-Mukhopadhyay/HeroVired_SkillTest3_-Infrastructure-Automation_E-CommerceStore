# ---------------------------------------------------------------
# Look-ups (data sources): READ existing info from AWS, create nothing
# ---------------------------------------------------------------

# Latest official Ubuntu 22.04 image, published by Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# List of availability zones (data centres) in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# ---------------------------------------------------------------
# Networking: VPC -> Internet Gateway -> Public Subnet -> Route Table
# ---------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # gives EC2 a public DNS name

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true # every EC2 here gets a public IP

  tags = { Name = "${var.project_name}-public-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # "Any address not inside the VPC -> send it out through the gateway"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------
# Security Group: the door guard's guest list
# ---------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg"
  description = "Frontend HTTP, backend service ports, SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP to frontend from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Backend services 3001-3004: inside the VPC + my IP for testing"
    from_port   = 3001
    to_port     = 3004
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.my_ip_cidr]
  }

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound (apt, Docker Hub pulls)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg" }
}

# ---------------------------------------------------------------
# EC2 instance that runs all containers
# ---------------------------------------------------------------

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # Fill the placeholders in user_data.sh, and strip Windows "\r" line endings
  user_data = replace(templatefile("${path.module}/user_data.sh", {
    dockerhub_username = var.dockerhub_username
    image_tag          = var.image_tag
    jwt_secret         = var.jwt_secret
  }), "\r", "")

  # If the script changes, rebuild the server so the new script runs
  user_data_replace_on_change = true

  tags = { Name = "${var.project_name}-server" }
}
