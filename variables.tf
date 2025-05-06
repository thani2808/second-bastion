variable "region" {
}

# variable "access_key" {
# }

# variable "secret_key" {
# }

variable "vpc_name" {
}

variable "vpc_cidr" {
}

variable "cidr_blocks_egress" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "private_subnets" {
  description = "Private Subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_names" {
  description = "Private Subnet Names"
  type        = list(string)
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public Subnet CIDRs"
  type        = list(string)
}

variable "public_subnet_names" {
  description = "Public Subnet Names"
  type        = list(string)
}

variable "ami" {
}

variable "key_name" {
}

variable "my-windows-keys" {
}

variable "instance_type" {
}

# variable "public_key" {
# }

variable "cidr_blocks_ingress_bastion" {
  type    = list(string)
  default = ["49.204.112.136/32"] # This is my home IPAdress
  #default = ["45.119.28.0/24"] # This is Raj home IPAdress
}