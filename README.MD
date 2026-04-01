
# Ecommerce Infrastructure

Production-ready AWS infrastructure for containerized applications using Terraform and GitHub Actions.

## Architecture Overview

┌─────────────────────────────────────┐
│           GitHub Actions            │
│  ┌─────────┐    ┌─────────────┐    │
│  │  Plan   │───▶│   Apply     │    │
│  │ (dev)   │    │   (main)    │    │
│  └─────────┘    └─────────────┘    │
└──────────┬──────────────────────────┘
│
▼
┌─────────────────────────────────────┐
│              AWS Cloud              │
│  ┌─────────────────────────────┐    │
│  │      Application Load       │    │
│  │         Balancer            │    │
│  └─────────────┬───────────────┘    │
│                │                    │
│  ┌─────────────▼───────────────┐    │
│  │      ECS Fargate            │    │
│  │   ┌─────────────────────┐   │    │
│  │   │   Node.js API       │   │    │
│  │   │   (Docker)          │   │    │
│  │   └─────────────────────┘   │    │
│  └─────────────┬───────────────┘    │
│                │                    │
│  ┌─────────────▼───────────────┐    │
│  │      RDS Proxy              │    │
│  └─────────────┬───────────────┘    │
│                │                    │
│  ┌─────────────▼───────────────┐    │
│  │   RDS PostgreSQL            │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │   ElastiCache Redis         │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
plain
Copy


## Repository Structure

ecommerce-infra/
├── .github/
│   └── workflows/
│       ├── infrastructure.yml    # Deploy pipeline
│       └── destroy.yml           # Teardown pipeline
├── envs/
│   └── dev/
│       ├── main.tf              # Environment config
│       ├── variables.tf         # Input variables
│       ├── outputs.tf           # Exported values
│       └── backend.tf           # State backend
└── modules/                     # Reusable modules (external)
plain
Copy


## External Modules

This repo consumes modules from [Cloud-Infra-Modules](https://github.com/Vcthriee/Cloud-Infra-Modules):

| Module | Purpose |
|--------|---------|
| `networking` | VPC, subnets, NAT gateways, route tables |
| `security` | Security groups for ALB, ECS, RDS, Redis |
| `database` | RDS PostgreSQL, RDS Proxy, ElastiCache Redis |
| `ecs` | ECS cluster, service, task definitions, ALB |

## Usage

### Deploy Infrastructure

```bash
# Push to dev branch - runs plan only
git checkout dev
git push origin dev

# Merge to main - runs plan + apply
git checkout main
git merge dev
git push origin main

Destroy Infrastructure
Manual trigger via GitHub Actions:

    Go to Actions → Destroy Infrastructure
    Click "Run workflow"
    Type DESTROY to confirm

Configuration
Store environment variables in S3:
bash
Copy

aws s3 cp terraform.tfvars s3://cloudthrieesecurity-terraform-tfvars/ecommerce-infra/dev.tfvars

Required variables:
hcl
Copy

project_name = "ecommerce-app"
aws_account_id = "904690835870"
aws_region = "af-south-1"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["af-south-1a", "af-south-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
private_data_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
environment = "dev"
db_name = "ecommerce_db"
db_username = "dbadmin"
ecs_cpu = "256"
ecs_memory = "1024"
ecs_desired_count = 2
jwt_secret = "your-jwt-secret-here"

Outputs
Table
Output	Description
alb_url	Application Load Balancer endpoint
ecr_repo_url	Container registry URL
ecs_cluster_name	ECS cluster identifier
ecs_service_name	ECS service identifier
rds_proxy_endpoint	Database proxy endpoint (sensitive)
redis_endpoint	Redis cache endpoint (sensitive)
Security Features

    OIDC authentication (no long-lived AWS credentials)
    Secrets in AWS Secrets Manager
    State encryption in S3 with DynamoDB locking
    VPC endpoints for AWS services
    Security groups with least privilege
    Private subnets for databases and applications

Network Layout
plain
Copy

VPC (10.0.0.0/16)
├── Public Subnets (ALB, NAT)
│   ├── 10.0.1.0/24 (AZ-1)
│   └── 10.0.2.0/24 (AZ-2)
├── Private App Subnets (ECS)
│   ├── 10.0.3.0/24 (AZ-1)
│   └── 10.0.4.0/24 (AZ-2)
└── Private Data Subnets (RDS, Redis)
    ├── 10.0.5.0/24 (AZ-1)
    └── 10.0.6.0/24 (AZ-2)

CI/CD Pipeline
Table
Branch	Trigger	Action
dev	Push	Terraform Plan (preview)
main	Push	Terraform Plan + Apply (deploy)
License