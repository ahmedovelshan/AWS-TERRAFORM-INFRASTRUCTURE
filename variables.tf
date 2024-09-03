variable "vpc" {
  type = string
  description = "VPC CIDR"
  default = "10.0.0.0/16"
}

variable "public-subnet-cidr" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zone" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

variable "openvpnec2-port" {
  description = "List of ports to allow"
  type = list(string)
  default = ["1194"]
}

variable "wikiec2-port" {
  description = "List of ports to allow"
  type = list(string)
  default = ["80"]
}

variable "vm-count" {
  description = "List of ports to allow"
  type = string
  default = "2"
}
