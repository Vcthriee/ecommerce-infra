

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Creates VPC, subnets, NAT gateways, route tables, VPC endpoints
module "networking" {
  source = "github.com/Vcthriee/Cloud-Infra-Modules//modules/networking"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_app_cidrs   = var.private_app_cidrs
  private_data_cidrs  = var.private_data_cidrs
}

# Creates security groups for ALB, ECS, RDS Proxy, RDS, ElastiCache
module "security" {
  source = "github.com/Vcthriee/Cloud-Infra-Modules//modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

# Creates RDS PostgreSQL, RDS Proxy, ElastiCache Redis
# Generates its own random password and stores it in Secrets Manager
module "database" {
  source = "github.com/Vcthriee/Cloud-Infra-Modules//modules/database"

  project_name                  = var.project_name
  private_data_subnet_ids       = module.networking.private_data_subnet_ids
  rds_security_group_id         = module.security.rds_security_group_id
  rds_proxy_security_group_id   = module.security.rds_proxy_security_group_id
  elasticache_security_group_id = module.security.elasticache_security_group_id
  db_instance_class             = var.db_instance_class
  db_name                       = var.db_name
  db_username                   = var.db_username
}

# JWT secret stored in Secrets Manager
# ecommerce-infra owns this secret because it is app-specific
# The database module owns the db password secret
resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "${var.project_name}-jwt-secret"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.jwt_secret
}

# Creates ECS cluster, ECR repo, ALB, task definition, ECS service
# Passes ARNs to ECS so it can read secrets at runtime
module "ecs" {
  source = "github.com/Vcthriee/Cloud-Infra-Modules//modules/ecs"

  project_name           = var.project_name
  aws_region             = var.aws_region
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  alb_security_group_id  = module.security.alb_security_group_id
  ecs_security_group_id  = module.security.ecs_security_group_id
  db_proxy_endpoint      = module.database.rds_proxy_endpoint
  redis_endpoint         = module.database.redis_endpoint
  db_secret_arn          = module.database.db_secret_arn
  jwt_secret_arn         = aws_secretsmanager_secret.jwt_secret.arn
  db_name                = var.db_name
  db_username            = var.db_username
  ecs_cpu                = var.ecs_cpu
  ecs_memory             = var.ecs_memory
  ecs_desired_count      = var.ecs_desired_count

}# Trigger workflow
