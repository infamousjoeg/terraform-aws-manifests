provider "aws" {
  region = local.region
}

provider "cloudflare" {}

# provider "acme" {
#   server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
# }

resource "aws_instance" "jenkins" {
  ami                           = data.aws_ami.latest.id
  instance_type                 = local.instance_type

  key_name                      = local.key_name
  iam_instance_profile          = local.iam_instance_profile
  vpc_security_group_ids        = local.vpc_security_group_ids
  associate_public_ip_address   = local.associate_public_ip_address
  tags                          = local.tags

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/cyberark-pasaas.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum upgrade -y",
      "sudo amazon-linux-extras install java-openjdk11 -y",
      "sudo yum install -y jenkins",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl stop jenkins",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "aws s3 cp s3://demo-state-store/jenkins/override.conf /tmp/override.conf",
      "sudo mkdir -p /etc/systemd/system/jenkins.service.d/",
      "sudo cp /tmp/override.conf /etc/systemd/system/jenkins.service.d/override.conf",
      "aws s3 cp s3://demo-state-store/jenkins/var_lib_jenkins.zip /tmp/config.zip",
      "sudo unzip -o /tmp/config.zip -d /var/lib/",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/*",
      
      # Importing jenkins.jks into Java Keystore
      "sudo keytool -importkeystore -srckeystore /var/lib/jenkins/jenkins.jks -destkeystore /usr/lib/jvm/java-11-openjdk-11.0.20.0.8-1.amzn2.0.1.x86_64/lib/security/cacerts -srcstorepass Cyberark1 -deststorepass changeit -noprompt",

      # Start Jenkins service
      "sudo systemctl daemon-reload",
      "sudo systemctl start jenkins",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
        "sudo systemctl stop jenkins",
        "cd /var/lib",
        "sudo zip -r /tmp/new-config.zip jenkins",
        "aws s3 cp /tmp/new-config.zip s3://demo-state-store/jenkins/var_lib_jenkins.zip",
    ]

    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("~/cyberark-pasaas.pem")
        host        = self.public_ip
    }
  }
}

resource "aws_security_group_rule" "conjur" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.jenkins.public_ip}/32"]
  description       = "Jenkins"
  security_group_id = "sg-029c2e642aaacb1a3"
}

resource "cloudflare_record" "jenkins" {
    zone_id = data.cloudflare_zone.this.zone_id
    name    = "jenkins"
    value   = aws_instance.jenkins.public_ip
    type    = "A"
    proxied = false
}

# resource "tls_private_key" "private_key" {
#   algorithm = "RSA"
# }

# resource "acme_registration" "reg" {
#   account_key_pem = tls_private_key.private_key.private_key_pem
#   email_address   = "joe@joe-garcia.com"
# }

# resource "acme_certificate" "certificate" {
#   account_key_pem           = acme_registration.reg.account_key_pem
#   common_name               = "jenkins.infamousapps.com"

#   dns_challenge {
#     provider = "cloudflare"
#   }
# }