output "project_info" {
  description = "Basic project information"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
  }
}

output "monitored_ec2_info" {
  description = "Information about the existing EC2 instance"
  value = {
    instance_id       = data.aws_instance.monitored_ec2.id
    instance_type     = data.aws_instance.monitored_ec2.instance_type
    availability_zone = data.aws_instance.monitored_ec2.availability_zone
    private_ip        = data.aws_instance.monitored_ec2.private_ip
    public_ip         = data.aws_instance.monitored_ec2.public_ip
  }
}