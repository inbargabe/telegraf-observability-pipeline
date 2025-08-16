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

data "aws_instance" "monitored_ec2" {
  instance_id = var.monitored_ec2_instance_id
}

locals {
  telegraf_install_script = base64encode(templatefile("${path.module}/scripts/install-telegraf.sh", {
    kinesis_stream_name = "${var.project_name}-metrics"
    aws_region         = var.aws_region
  }))
}

data "aws_vpc" "monitored_ec2_vpc" {
  id = data.aws_instance.monitored_ec2.vpc_id
}

# Telegraf SG
resource "aws_security_group" "telegraf_sg" {
  name_prefix = "telegraf-sg-"
  description = "Security group for Telegraf monitoring"
  vpc_id      = data.aws_vpc.monitored_ec2_vpc.id

  # Outbound rules for Telegraf
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

  tags = {
    Name        = "telegraf-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "telegraf_kinesis_policy" {
  name        = "telegraf-kinesis-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = "arn:aws:kinesis:${var.aws_region}:*:stream/telegraf-observability-metrics"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "telegraf_kinesis_role" {
  name = "telegraf-kinesis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "telegraf_kinesis_attachment" {
  role       = aws_iam_role.telegraf_kinesis_role.name
  policy_arn = aws_iam_policy.telegraf_kinesis_policy.arn
}

resource "aws_iam_instance_profile" "telegraf_instance_profile" {
  name = "telegraf-instance-profile"
  role = aws_iam_role.telegraf_kinesis_role.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_network_interface_sg_attachment" "telegraf_sg_attachment" {
  security_group_id    = aws_security_group.telegraf_sg.id
  network_interface_id = data.aws_instance.monitored_ec2.network_interface_id
}

resource "aws_iam_instance_profile_association" "telegraf_profile_association" {
  instance_id  = data.aws_instance.monitored_ec2.id
  iam_instance_profile = aws_iam_instance_profile.telegraf_instance_profile.name