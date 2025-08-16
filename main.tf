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
    kinesis_stream_name = "${var.project_name}-${var.environment}-metrics"
    aws_region         = var.aws_region
  }))
}