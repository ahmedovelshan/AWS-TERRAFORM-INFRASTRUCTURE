data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] 
}

resource "aws_network_interface" "interface-ec2-openvpn" {
  subnet_id   = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.www-to-openvpnec2.id]
}

resource "aws_network_interface" "interface-ec2-wiki" {
  subnet_id   = module.vpc.public_subnets[1]
  security_groups = [aws_security_group.www-to-wikiec2.id]
}


resource "aws_instance" "ec2-openvpn" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  iam_instance_profile = "AWSSessionManagerProfile"
  

  network_interface {
    network_interface_id = aws_network_interface.interface-ec2-openvpn.id
    device_index         = 0
  }
  user_data = file("openvpn-setup.sh")
}


resource "aws_eip" "ec2-openvpn-eip" {
  instance = aws_instance.ec2-openvpn.id
  domain   = "vpc"
}


resource "aws_instance" "ec2-wiki" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  iam_instance_profile = "AWSSessionManagerProfile"
  

  network_interface {
    network_interface_id = aws_network_interface.interface-ec2-wiki.id
    device_index         = 0
  }
  user_data = file("wiki-setup.sh")
}


resource "aws_eip" "ec2-wiki-eip" {
  instance = aws_instance.ec2-wiki.id
  domain   = "vpc"
}

