# modules/network/outputs.tf

output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the created VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "A map of public subnet IDs, keyed by their input name."
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "A map of private subnet IDs, keyed by their input name."
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "public_route_table_id" {
  description = "The ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "The ID of the private route table."
  value       = aws_route_table.private.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway (if created)."
  value       = var.create_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "default_security_group_id" {
  description = "The ID of the default security group created by this module."
  value       = aws_security_group.default.id
}