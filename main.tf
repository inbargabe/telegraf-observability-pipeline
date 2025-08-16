terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_instance" "monitored_ec2" {
  instance_id = var.monitored_ec2_instance_id
}

data "aws_subnet" "monitored_ec2_subnet" {
  id = data.aws_instance.monitored_ec2.subnet_id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Groups
resource "aws_security_group" "telegraf_sg" {
  name_prefix = "telegraf-sg-"
  vpc_id      = data.aws_subnet.monitored_ec2_subnet.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8086
    to_port     = 8086
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.monitored_ec2_subnet.cidr_block]
  }

  tags = {
    Name        = "telegraf-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "obs_sg" {
  name_prefix = "obs-sg-"
  vpc_id      = data.aws_subnet.monitored_ec2_subnet.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8086
    to_port         = 8086
    protocol        = "tcp"
    security_groups = [aws_security_group.telegraf_sg.id]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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
    Name        = "obs-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_instance" "obs_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.obs_sg.id]
  subnet_id             = data.aws_instance.monitored_ec2.subnet_id

  user_data = base64encode(templatefile("${path.module}/scripts/install-observability-stack.sh", {
    environment = var.environment
  }))

  tags = {
    Name        = "obs-server"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_eip" "obs_server_eip" {
  domain   = "vpc"
  instance = aws_instance.obs_server.id

  tags = {
    Name        = "obs-server-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group Attachment
resource "aws_network_interface_sg_attachment" "telegraf_sg_attachment" {
  security_group_id    = aws_security_group.telegraf_sg.id
  network_interface_id = data.aws_instance.monitored_ec2.network_interface_id
}

# Locals for scripts
locals {
  telegraf_install_script = base64encode(templatefile("${path.module}/scripts/install-telegraf.sh", {
    influxdb_server_ip = aws_instance.obs_server.private_ip
    aws_region         = var.aws_region
  }))
}