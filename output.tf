

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "web_server_public_ip" {
  value = aws_instance.app_server.public_ip
}
