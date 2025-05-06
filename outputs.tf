output "private_subnet_id" {
  value = module.vpc.private_subnets
}

# output "public_subnet_id" {
#   value = module.vpc.public_subnets
# }

output "public_subnets_output" {
  value = module.vpc.public_subnets
}


output "IGW_id" {
  value = module.vpc.igw_id
}

output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "available_azs" {
  value = data.aws_availability_zones.available.names
}

# output "azs" {
#   value = data.aws_availability_zones.available.names
# }

# output "windows_instance_id" {
#   value = aws_instance.firs_windows_image_instance.id
# }