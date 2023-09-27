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

data "cloudflare_zone" "infamousdevops" {
  zone_id = var.cloudflare_zone_id
}

locals {
  region = "us-east-1"
  instance_type = "t3.medium"
  key_name = "cyberark-pasaas"
  iam_instance_profile = "AllowEC2AccessS3demo-state-store"
  vpc_security_group_ids = [
    "sg-02c6b717bafd9e093",
    "sg-07922b3d9943dbcfb",
    "sg-0002bcd921109a02a"
  ]
  associate_public_ip_address = true
  tags = {
    Name = "Jenkins"
    role = "cicd"
    cloudflare_dns = "jenkins.infamousdevops.com"
  }
}