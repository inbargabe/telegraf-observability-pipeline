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

output "iam_resources" {
  value = {
    role_name             = aws_iam_role.telegraf_kinesis_role.name
    role_arn              = aws_iam_role.telegraf_kinesis_role.arn
    policy_name           = aws_iam_policy.telegraf_kinesis_policy.name
    instance_profile_name = aws_iam_instance_profile.telegraf_instance_profile.name
  }
}

output "security_group_info" {
  value = {
    security_group_id   = aws_security_group.telegraf_sg.id
    security_group_name = aws_security_group.telegraf_sg.name
  }
}