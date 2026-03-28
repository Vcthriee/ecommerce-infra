

# The URL to access your app after deployment
output "alb_url" {
  value = "http://${module.ecs.alb_dns_name}"
}

# ECR repo URL — GitHub Actions pushes Docker images here
output "ecr_repo_url" {
  value = module.ecs.ecr_repository_url
}

# ECS cluster and service names — GitHub Actions uses these to deploy
output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

# Database endpoints — sensitive so Terraform hides them in terminal output
output "rds_proxy_endpoint" {
  value     = module.database.rds_proxy_endpoint
  sensitive = true
}

output "redis_endpoint" {
  value     = module.database.redis_endpoint
  sensitive = true
}