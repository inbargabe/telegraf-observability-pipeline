#!/bin/bash
# scripts/install-observability-stack.sh


### BEFORE RUNNING THE SCRIPT - Add an Environmet variable on the machine with the following:
# GRAFANA_ADMIN_PASSWORD=<desired password>
set -e

exec > >(tee /var/log/observability-install.log)
exec 2>&1

yum update -y

yum install -y wget curl

# Install InfluxDB
echo "Installing InfluxDB..."
cat <<EOF > /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

yum install -y influxdb

# Configure InfluxDB
cat <<EOF > /etc/influxdb/influxdb.conf
[meta]
  dir = "/var/lib/influxdb/meta"

[data]
  dir = "/var/lib/influxdb/data"
  wal-dir = "/var/lib/influxdb/wal"

[http]
  enabled = true
  bind-address = ":8086"
  auth-enabled = false
  log-enabled = true
  write-tracing = false
  pprof-enabled = true
  debug-pprof-enabled = false
  https-enabled = false

[logging]
  level = "info"
EOF

# Start and enable InfluxDB
systemctl enable influxdb
systemctl start influxdb

# Wait for InfluxDB to start
sleep 10

# Create database for Telegraf metrics
influx -execute 'CREATE DATABASE telegraf'
influx -execute 'SHOW DATABASES'

echo "InfluxDB installation completed"

# Install Grafana
echo "Installing Grafana..."
cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

yum install -y grafana

# Configure Grafana
cat <<EOF > /etc/grafana/grafana.ini
[DEFAULT]
instance_name = obs-server

[server]
http_port = 3000
domain = localhost

[security]
admin_user = admin
admin_password = $GRAFANA_ADMIN_PASSWORD

[database]
type = sqlite3
path = grafana.db

[session]
provider = file

[analytics]
reporting_enabled = false
check_for_updates = false

[log]
mode = file
level = info

[paths]
data = /var/lib/grafana
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins
provisioning = /etc/grafana/provisioning
EOF

# Create Grafana directories
mkdir -p /etc/grafana/provisioning/datasources
mkdir -p /etc/grafana/provisioning/dashboards

# Configure InfluxDB datasource for Grafana
cat <<EOF > /etc/grafana/provisioning/datasources/influxdb.yaml
apiVersion: 1

datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://localhost:8086
    database: telegraf
    isDefault: true
    editable: true
EOF

# Start and enable Grafana
systemctl enable grafana-server
systemctl start grafana-server

# Check services status
echo "Checking services status..."
systemctl status influxdb --no-pager
systemctl status grafana-server --no-pager

# Get public IP for access info
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "Installation completed at $(date)"
echo "============================================"
echo "InfluxDB URL: http://$PUBLIC_IP:8086"
echo "Grafana URL: http://$PUBLIC_IP:3000"
echo "InfluxDB Database: telegraf"
echo "============================================"
echo "Logs:"
echo "- InfluxDB: journalctl -u influxdb -f"
echo "- Grafana: journalctl -u grafana-server -f"
echo "- This script: tail -f /var/log/observability-install.log"