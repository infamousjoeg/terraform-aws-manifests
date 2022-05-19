provider "conjur" {}

# Get the AWS Access Key ID from Conjur
data "conjur_secret" "aws_access_key_id" {
  name = "SyncVault/LOB_CD/D-CD-Terraform/Cloud Service-AWSAccessKeys-terraform/awsaccesskeyid"
}
# Get the AWS Secret Access Key from Conjur
data "conjur_secret" "aws_secret_access_key" {
  name = "SyncVault/LOB_CD/D-CD-Terraform/Cloud Service-AWSAccessKeys-terraform/password"
}

provider "aws" {
  access_key = data.conjur_secret.aws_access_key_id.value
  secret_key = data.conjur_secret.aws_secret_access_key.value
  region = "us-east-1"
}

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
  key_name                    = "krypton-20211014"
  vpc_security_group_ids      = ["sg-02c6b717bafd9e093"]

  tags = {
    Name = "Ubuntu Client"
    role = "client_ubuntu"
  }
}
