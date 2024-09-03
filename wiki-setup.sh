#!/bin/bash
sudo apt update -y
sudo systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service
git clone https://github.com/ahmedovelshan/AWS-TERRAFORM-INFRASTRUCTURE.git
cd AWS-TERRAFORM-INFRASTRUCTURE
chmod a+x installation-ubuntu-24.04.sh
sudo ./installation-ubuntu-24.04.sh


