#Output IP of wordpress instance
output "wp-ip" {
  value = aws_lb.crc-wp-alb.dns_name
}

#output database endpoint
output "rds-endpoing" {
  value = aws_db_instance.rds-mysql-wp.endpoint
}

