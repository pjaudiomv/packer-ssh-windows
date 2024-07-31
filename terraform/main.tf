terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "vpc_id" {
  type = string
}

data "aws_partition" "this" {}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:${data.aws_partition.this.id}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "default_ssm_role" {
  name = "DefaultSSMProfileRole"
  path = "/"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = "sts:AssumeRole"
          Principal = {
            Service = "ec2.${data.aws_partition.this.dns_suffix}"
          }
          Effect = "Allow"
          Sid    = ""
        }
      ]
  })
  inline_policy {}
  managed_policy_arns = [data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn]
}

resource "aws_iam_instance_profile" "default_ssm_instance_profile" {
  name = "DefaultSSMProfile"
  role = aws_iam_role.default_ssm_role.name
}

resource "aws_security_group" "packer" {
  name        = "packer-ssm-egress-all"
  description = "Security group with egress all for Packer"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "packer-ssm"
  }
}
