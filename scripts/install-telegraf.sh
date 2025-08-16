#!/bin/bash
# scripts/install-telegraf.sh

set -e

# Log everything
exec > >(tee /var/log/telegraf-install.log)
exec 2>&1

echo "Starting Telegraf installation at $(date)"

# Detect OS and install Telegraf accordingly
if [ -f /etc/debian_version ]; then
    # Ubuntu/Debian
    echo "Detected Debian/Ubuntu system"

    # Add InfluxData repository
    curl -s https://repos.influxdata.com/influxdb.key | gpg --dearmor > /etc/apt/trusted.gpg.d/influxdb.gpg
    echo "deb https://repos.influxdata.com/debian stable main" > /etc/apt/sources.list.d/influxdata.list

    # Update package list and install
    apt-get update
    apt-get install -y telegraf awscli

elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL/Amazon Linux
    echo "Detected RedHat/CentOS/Amazon Linux system"

    # Add InfluxData repository
    cat <<EOF > /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

    # Install packages
    yum update -y
    yum install -y telegraf awscli
else
    echo "Unsupported operating system"
    exit 1
fi

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

# Output plugin - AWS Kinesis
[[outputs.kinesis]]
  region = "${aws_region}"
  streamname = "${kinesis_stream_name}"

  # Data format
  data_format = "json"
  json_timestamp_units = "1s"

  # Partitioning
  partition_key = "host"

  # Use instance profile for authentication
  use_default_credential_provider_chain = true

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