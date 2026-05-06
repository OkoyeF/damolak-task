output "cluster_name" { value = aws_ecs_cluster.main.name }
output "service_name" { value = aws_ecs_service.app.name }
output "alb_dns_name" { value = aws_lb.app.dns_name }
