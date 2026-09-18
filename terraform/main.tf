terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_security_group" "devops_api_sg" {
  name        = "terraform-devops-api-sg"
  description = "Security group created with Terraform"

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-devops-api-sg"
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "terraform-devops-api-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "terraform-devops-api-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_instance" "devops_api_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data_replace_on_change = true

  vpc_security_group_ids = [
    aws_security_group.devops_api_sg.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              set -e

              apt-get update -y

              apt-get install -y docker.io awscli

              systemctl enable docker
              systemctl start docker

              usermod -aG docker ubuntu

              if ! snap list amazon-ssm-agent >/dev/null 2>&1; then
                snap install amazon-ssm-agent --classic
              fi

              systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
              systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service
              EOF

  tags = {
    Name = "terraform-devops-api-ec2"
  }
}