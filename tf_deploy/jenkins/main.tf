provider "aws" {
  region = "us-east-1"
}

provider "cloudflare" {}

resource "aws_instance" "jenkins" {
  ami                           = data.aws_ami.latest.id
  instance_type                 = "t2.micro"

  key_name                      = "cyberark-pasaas"
  iam_instance_profile          = "AllowEC2AccessS3demo-state-store"
  vpc_security_group_ids        = [
                                    "sg-02c6b717bafd9e093",
                                    "sg-07922b3d9943dbcfb"
                                ]
  associate_public_ip_address   = true

  tags                          = {
                                    Name = "Jenkins",
                                    role = "cicd",
                                    cloudflare_dns = "jenkins.joegarcia.dev"
                                }

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

  provisioner "file" {
      source      = "files/override.conf"
      destination = "/tmp/override.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/systemd/system/jenkins.service.d/",
      "sudo cp /tmp/override.conf /etc/systemd/system/jenkins.service.d/override.conf",
      "aws s3 cp s3://demo-state-store/var_lib_jenkins.zip /tmp/config.zip",
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
        "aws s3 cp /tmp/new-config.zip s3://demo-state-store/var_lib_jenkins.zip",
    ]

    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("~/cyberark-pasaas.pem")
        host        = self.public_ip
    }
  }
}

resource "cloudflare_record" "jenkins" {
    zone_id = data.cloudflare_zone.this.zone_id
    name    = "jenkins"
    value   = aws_instance.jenkins.public_ip
    type    = "A"
    proxied = false
}