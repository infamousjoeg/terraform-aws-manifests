provider "aws" {}

# Save AMI ID to data.aws_ami.latest.id
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "ubuntu_client" {
  ami                         = data.aws_ami.latest.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "Krypton-20191020"
  vpc_security_group_ids      = ["sg-02c6b717bafd9e093"]

  tags = {
    Name = "Ubuntu Client"
    role = "client_ubuntu"
  }
}