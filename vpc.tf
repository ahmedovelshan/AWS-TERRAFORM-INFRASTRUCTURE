module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "cloud-vpc"
  cidr = var.vpc

  azs             = var.availability_zone
  public_subnets  = var.public-subnet-cidr
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}


resource "aws_security_group" "www-to-openvpnec2" {
    vpc_id              = module.vpc.vpc_id
    name                = "www-to-openvpnec2"
    description         = "Access from WWW to EC2 which openvpn installed"
    dynamic "ingress" {
        for_each = var.openvpnec2-port
        content {
          protocol = "tcp"
          from_port = ingress.value
          to_port = ingress.value
          cidr_blocks = [ "0.0.0.0/0" ]
        }      
    }
    egress {
        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}


resource "aws_security_group" "www-to-wikiec2" {
    vpc_id              = module.vpc.vpc_id
    name                = "www-to-wikiec2"
    description         = "Access from WWW to EC2 which Wiki installed"
    dynamic "ingress" {
        for_each = var.wikiec2-port
        content {
          protocol = "tcp"
          from_port = ingress.value
          to_port = ingress.value
          cidr_blocks = [ "0.0.0.0/0" ]
        }      
    }
    egress {
        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}
