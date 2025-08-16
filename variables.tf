variable "aws_region" {
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  type        = string
  default     = "telegraf-observability"
}

variable "environment" {
  type        = string
  default     = "dev"
}

variable "monitored_ec2_instance_id" {
  type        = string
  default     = "i-0a38890c670c2c556"
}

variable "key_pair_name" {
  type    = string
  default = "telegraf-obs-key"
}
