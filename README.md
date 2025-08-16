
# Telegraf Observability Pipeline

A complete observability solution using Telegraf, InfluxDB, and Grafana, all provisioned with Terraform.

## Architecture

```
EC2 (Telegraf) → InfluxDB → Grafana Dashboard
```

## Components

- **Telegraf**: Collects system metrics from EC2 instance
- **InfluxDB**: Time-series database for metric storage
- **Grafana**: Visualization and monitoring dashboard

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- An existing EC2 instance to monitor

## Deployment Steps

1. Setup Terraform and Git
2. Install Telegraf on EC2
3. Configure EC2 security groups and IAM policies
6. Deploy InfluxDB and Grafana on another EC2
7. Configure IAM roles and policies
8. Setup Grafana dashboard


## Directory Structure

```
.
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf          # Output definitions
├── modules/            # Terraform modules (created as needed)
└── README.md           # This file
```

---