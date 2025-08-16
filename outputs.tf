output "project_info" {
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
  }
}

output "monitored_ec2_info" {
  value = {
    instance_id       = data.aws_instance.monitored_ec2.id
    instance_type     = data.aws_instance.monitored_ec2.instance_type
    availability_zone = data.aws_instance.monitored_ec2.availability_zone
    private_ip        = data.aws_instance.monitored_ec2.private_ip
    public_ip         = data.aws_instance.monitored_ec2.public_ip
  }
}

output "security_group_info" {
  value = {
    security_group_id   = aws_security_group.telegraf_sg.id
    security_group_name = aws_security_group.telegraf_sg.name
  }
}

output "observability_server_info" {
  value = {
    instance_id  = aws_instance.obs_server.id
    private_ip   = aws_instance.obs_server.private_ip
    public_ip    = aws_eip.obs_server_eip.public_ip
    grafana_url  = "http://${aws_eip.obs_server_eip.public_ip}:3000"
    influxdb_url = "http://${aws_eip.obs_server_eip.public_ip}:8086"
  }
}