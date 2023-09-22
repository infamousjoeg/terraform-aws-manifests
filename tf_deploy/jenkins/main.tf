# Initialize providers
provider "aws" {
  region = local.region
}

provider "cloudflare" {}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

# Generate self-signed private key for LetsEncrypt
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

# Register LetsEncrypt account
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "joe@joe-garcia.com"
}

# Generate LetsEncrypt certificate
resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "jenkins.infamousdevops.com"

  dns_challenge {
    provider = "cloudflare"
  }
}

resource "aws_s3_object" "certificate" {
  for_each = toset(["certificate_pem", "issuer_pem", "private_key_pem"])

  bucket = "demo-state-store"
  key = "jenkins/${each.key}"
  content = lookup(acme_certificate.certificate, each.key)
}

# Deploy AWS EC2 Instance for Jenkins
resource "aws_instance" "jenkins" {
  ami                           = data.aws_ami.latest.id
  instance_type                 = local.instance_type

  key_name                      = local.key_name
  iam_instance_profile          = local.iam_instance_profile
  vpc_security_group_ids        = local.vpc_security_group_ids
  associate_public_ip_address   = local.associate_public_ip_address
  tags                          = local.tags

  # Define connection for remote-exec provisioner
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/cyberark-pasaas.pem")
    host        = self.public_ip
  }

  # Update packages and install Jenkins
  provisioner "remote-exec" {
    inline = [
      "set -e",
      # Update packages and add Jenkins repo
      "sudo yum update -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum upgrade -y",

      # Install Java and Jenkins
      "sudo amazon-linux-extras install java-openjdk11 -y",
      "sudo yum install -y jenkins",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl stop jenkins",

      # Copy configuration files from S3 bucket
      "aws s3 cp s3://demo-state-store/jenkins /tmp/ --recursive",

      # Copy override.conf to /etc/systemd/system/jenkins.service.d/
      "sudo mkdir -p /etc/systemd/system/jenkins.service.d/",
      "sudo cp /tmp/override.conf /etc/systemd/system/jenkins.service.d/override.conf",
      
      # Copy var_lib_jenkins.zip to /var/lib/jenkins/
      "sudo unzip -o /tmp/var_lib_jenkins.zip -d /var/lib/",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/*",
      
      # Create Java Keystore for LetsEncrypt certificate
      "sudo rm -f /var/lib/jenkins/jenkins.jks",
      "openssl pkcs12 -export -in /tmp/certificate_pem -inkey /tmp/private_key_pem -out /tmp/jenkins.p12 -name jenkins.infamousapps.com -CAfile /tmp/issuer_pem -caname root -password pass:changeit",
      "sudo keytool -importkeystore -deststorepass changeit -destkeypass changeit -destkeystore /var/lib/jenkins/jenkins.jks -srckeystore /tmp/jenkins.p12 -srcstoretype PKCS12 -srcstorepass changeit -alias jenkins.infamousapps.com -noprompt -trustcacerts",

      # Importing jenkins.jks into Java Keystore
      "sudo keytool -importkeystore -srckeystore /var/lib/jenkins/jenkins.jks -destkeystore /usr/lib/jvm/java-11-openjdk-11.0.20.0.8-1.amzn2.0.1.x86_64/lib/security/cacerts -srcstorepass changeit -deststorepass changeit -noprompt",

      # Start Jenkins service
      "sudo systemctl daemon-reload",
      "sudo systemctl start jenkins",
    ]
  }

  # Copy Jenkins config to S3 bucket on destroy
  provisioner "remote-exec" {
    when = destroy
    inline = [
        "sudo systemctl stop jenkins",
        "cd /var/lib",
        "sudo rm -f jenkins.jks",
        "sudo zip -r /tmp/new-config.zip jenkins",
        "aws s3 cp /tmp/new-config.zip s3://demo-state-store/jenkins/var_lib_jenkins.zip",
    ]

    # Define connection for remote-exec provisioner
    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("~/cyberark-pasaas.pem")
        host        = self.public_ip
    }
  }
}

# Create Security Group Rule for Jenkins to Conjur access
resource "aws_security_group_rule" "conjur" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.jenkins.public_ip}/32"]
  description       = "Jenkins"
  security_group_id = "sg-029c2e642aaacb1a3"
}

# Create A Record in CloudFlare on infamousdevops.com for jenkins
resource "cloudflare_record" "jenkins" {
    zone_id = data.cloudflare_zone.infamousdevops.zone_id
    name    = "jenkins"
    value   = aws_instance.jenkins.public_ip
    type    = "A"
    proxied = false
}