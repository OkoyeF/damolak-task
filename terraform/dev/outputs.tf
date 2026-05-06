output "app_url" {
  value = "http://${module.ecs.alb_dns_name}"
}

output "cluster_name" {
  value = module.ecs.cluster_name
}

output "service_name" {
  value = module.ecs.service_name
}
