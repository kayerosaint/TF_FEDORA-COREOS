

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "web_server_public_ips" {
  value = aws_instance.app_server[*].public_ip
}

output "vpc_cidr_block" {
  value = try(data.aws_vpc.dev_vpc[*].cidr_block, "")
}

output "my_static_ips" {
  value = aws_eip.eip[*].public_ip
}







/*
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}
*/
