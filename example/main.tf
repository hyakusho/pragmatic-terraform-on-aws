provider "aws" {
  region = "ap-northeast-1"
}

variable "env" {}

variable "example_instance_type" {
  # -varオプション or 環境変数TF_VAR_<name>で上書き可能
  default = "t3.micro"
}

locals {
  # ローカル変数は上書きできない
  example_instance_type = "t3.micro"
}

data "aws_ami" "recent_amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name = "state"
    values = ["available"]
  }
}

data "template_file" "httpd_user_data" {
  template = file("./user_data.sh.tpl")

  vars = {
    package = "httpd"
  }
}

resource "aws_security_group" "example_ec2" {
  name = "example-ec2"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  #ami = "ami-0f310fced6141e627"
  ami = data.aws_ami.recent_amazon_linux_2.image_id
  #instance_type = "t3.micro"
  #instance_type = var.example_instance_type
  #instance_type = local.example_instance_type
  instance_type = var.env == "prod" ? "t3.micro" : "t3.nano"
  vpc_security_group_ids = [aws_security_group.example_ec2.id]

  tags = {
    Name = "example"
  }

#  user_data = <<EOF
#    #!/bin/bash
#    yum install -y httpd
#    systemctl start httpd.service
#EOF
  #user_data = file("./user_data.sh")
  user_data = data.template_file.httpd_user_data.rendered
}

output "example_instance_id" {
  value = aws_instance.example.id
}
