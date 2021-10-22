terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
     region  = var.region
     profile = "uat"   #<-- change your aws profile name
}


resource "aws_vpc" "devops-vpc"{
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "aws-infra" {
    source = "./modules/aws-infra"
    env_prefix        = var.env_prefix
    vpc_id            = aws_vpc.devops-vpc.id
}


module "aws-instance" {
    count = 1
    source = "./modules/aws-instance"
    public_key_location  = var.public_key_location
    private_key_location = var.private_key_location
    instance_type        = var.instance_type
    image_name           = var.image_name
    env_prefix           = var.env_prefix
    vpc_id               = aws_vpc.devops-vpc.id
    az_zone              = element(data.aws_availability_zones.available.names, count.index)
    subnet_id            = module.aws-infra.devops_private_subnets[count.index]
}

#SECURITY GROUP for ALB
resource "aws_security_group" "alb" {
  name        = "devops_alb_security_group"
  description = "DevOps load balancer security group"
  vpc_id      = aws_vpc.devops-vpc.id



  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags ={
    Name = "devops-alb-security-group"
  }
}


module "devops-alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "devops-alb"

  load_balancer_type = "application"

  vpc_id             = aws_vpc.devops-vpc.id
  subnets            = module.aws-infra.devops_public_subnets.*
  security_groups    = [aws_security_group.alb.id]



  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = [

        {
          target_id = module.aws-instance[0].instance_id
          port = 8080
        }
      ]
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }
}





