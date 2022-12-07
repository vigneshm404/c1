output "key_alias_arn" {
  description = "The arn of the key alias"
  # value       = element(aws_kms_alias.key_alias[0].arn
  value = aws_kms_alias.key_alias.arn
}



output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.external-elb.dns_name
}