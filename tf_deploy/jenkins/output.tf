output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.jenkins.id
}

output "public_ipv4_address" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.jenkins.public_dns
}

output "tags_assigned" {
  description = "All tags assigned to the EC2 instance"
  value       = aws_instance.jenkins.tags_all
}

output "cloudflare_record" {
  description = "Cloudflare record for Jenkins"
  value       = cloudflare_record.jenkins.name
}