output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ubuntu_client.id
}

output "public_ipv4_address" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.ubuntu_client.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ubuntu_client.public_dns
}

output "tags_assigned" {
  description = "All tags assigned to the EC2 instance"
  value       = aws_instance.ubuntu_client.tags_all
}