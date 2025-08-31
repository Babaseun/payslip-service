output "payslip_postgres_endpoint" {
  description = "The connection endpoint for the Payslip PostgreSQL database"
  value       = aws_db_instance.payslip_postgres_database.address
}


output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.payslip_nlb.dns_name
}

output "nlb_zone_id" {
  description = "The zone_id of the load balancer for DNS records"
  value       = aws_lb.payslip_nlb.zone_id
}

output "server_endpoint" {
  description = "Full endpoint to access the payslip server"
  value       = "${aws_lb.payslip_nlb.dns_name}:5000"
}

output "target_group_arn" {
  description = "ARN of the target group for auto scaling integration"
  value       = aws_lb_target_group.payslip_tg.arn
}
