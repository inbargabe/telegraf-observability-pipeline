#!/bin/bash
# scripts/install-telegraf.sh

set -e

# Log everything
exec > >(tee /var/log/telegraf-install.log)
exec 2>&1

echo "Starting Telegraf installation at $(date)"

cat <<EOF > /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

yum update -y
yum install -y telegraf awscli

# Create Telegraf configuration
cat <<EOF > /etc/telegraf/telegraf.conf
# Global settings
[global_tags]
  environment = "dev"
  region = "${aws_region}"

[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = ""
  omit_hostname = false

# Input plugins - Basic system metrics
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "overlay", "aufs", "squashfs"]

[[inputs.diskio]]

[[inputs.kernel]]

[[inputs.mem]]

[[inputs.processes]]

[[inputs.swap]]

[[inputs.system]]

[[inputs.net]]

[[outputs.influxdb]]
  urls = ["http://${influxdb_server_ip}:8086"]
  database = "telegraf"

  # InfluxDB connection settings
  timeout = "5s"
  username = ""
  password = ""

  # Data format
  precision = "s"

EOF

# Enable and start Telegraf service
systemctl enable telegraf
systemctl start telegraf

# Check status
systemctl status telegraf --no-pager

echo "Telegraf installation completed at $(date)"
echo "Configuration file: /etc/telegraf/telegraf.conf"
echo "Service status: $(systemctl is-active telegraf)"
echo "Logs: journalctl -u telegraf -f"
echo "InfluxDB target: ${influxdb_server_ip}:8086"
