variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "telegraf-observability"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "monitored_ec2_instance_id" {
  description = "ID of the EC2 instance to monitor"
  type        = string
  default     = "i-0a38890c670c2c556"
}
