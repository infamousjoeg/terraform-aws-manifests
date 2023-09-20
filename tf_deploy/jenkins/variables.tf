# Save AMI ID for latest Amazon 2 amd64 image to data.aws_ami.latest.id
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
}

data "cloudflare_zone" "this" {
  zone_id = var.cloudflare_zone_id
}