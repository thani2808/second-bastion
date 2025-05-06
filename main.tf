provider "aws" {
  region = var.region
  #access_key = var.access_key
  #secret_key = var.secret_key
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs                  = var.azs
  private_subnets      = var.private_subnets
  private_subnet_names = var.private_subnet_names
  public_subnets       = var.public_subnets
  public_subnet_names  = var.public_subnet_names

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  public_subnet_tags = {
    subnet                   = "public"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    subnet                            = "private"
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "dev" {
  vpc_id = module.vpc.vpc_id

  # Define ingress and egress rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust as necessary
    description = "Allow SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "dev Security Group"
  }
}

# resource "aws_instance" "dev_ec2_public" {
#   count                       = length(module.vpc.public_subnets)
#   ami                         = var.ami
#   instance_type               = var.instance_type
#   subnet_id                   = module.vpc.public_subnets[count.index]
#   key_name                    = var.key_name
#   vpc_security_group_ids      = [aws_security_group.dev.id]
#   associate_public_ip_address = true # 🔑 Needed to get public IP

#   tags = {
#     Name = "EC2-${count.index}"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sleep 30",
#       "touch hello.txt",
#       "echo helloworld remote provisioner >> hello.txt",
#     ]
#   }
#   connection {
#     type        = "ssh"
#     host        = self.public_ip
#     user        = "ubuntu"
#     private_key = file("/home/thani/.ssh/id_rsa")
#     timeout     = "12m"
#   }
# }



resource "aws_instance" "dev_ec2_private" {
  count                  = length(module.vpc.private_subnets)
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = module.vpc.private_subnets[count.index]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.private_ec2.id]

  tags = {
    Name = "EC2-${count.index}"
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sleep 30",
  #     "touch hello.txt",
  #     "echo helloworld remote provisioner >> hello.txt",
  #   ]
  # }

  depends_on = [aws_instance.bastion]

  connection {
    type                = "ssh"
    host                = self.private_ip
    user                = "ubuntu"
    private_key         = file("/home/thani/.ssh/id_rsa_555")
    bastion_host        = aws_instance.bastion.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = file("/home/thani/.ssh/id_rsa_555")
    timeout             = "12m"
  }
}

# locals {
#   ingress_rules = [{
#     port        = 80
#     description = "Ingress rules for port 80"
#     },
#     {
#       port        = 3389
#       description = "Ingress rules for port 3389"
#     },
#     {
#       port        = 22
#       description = "Ingress rules for port 22"
#   }]
# }

resource "aws_security_group" "ansible_bastion_sg" {
  vpc_id      = module.vpc.vpc_id
  name        = "bastion-sg"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_ingress_bastion
    description = "Allow SSH from my IP to Bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks_egress
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ansible_bastion_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y software-properties-common git vim
              
              add-apt-repository --yes --update ppa:ansible/ansible
              apt install -y ansible >> /var/log/ansible-install.log 2>&1
              echo "Ansible installed successfully" >> /var/log/ansible-install.log

              # Install Git
              apt install -y git

              # Clone the Git repository (replace with your repo URL)
              git clone https://github.com/thani2808/first-bastion.git /opt/ansible-playbooks

              echo "Git repo cloned successfully" >> /var/log/ansible-install.log              
              EOF

  tags = {
    Name = "Bastion"
  }
}

resource "aws_security_group" "private_ec2" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ansible_bastion_sg.id]
    description     = "Allow SSH from Bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks_egress
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "Private-EC2-Security-Group"
  }
}

# resource "aws_key_pair" "deployer" {
#   key_name   = var.key_name
#   public_key = var.public_key
# }

# resource "aws_security_group" "firs_windows_image_sg" {
#   name        = "firs_windows_image_sg"
#   vpc_id      = module.vpc.vpc_id
#   description = "Allow RDP"
#   ingress {
#     from_port   = 3389
#     to_port     = 3389
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # You should restrict this in production!
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_instance" "firs_windows_image_instance" {
#   ami                         = "ami-0907008e2c2a9e429" # Example Windows AMI (adjust this!)
#   instance_type               = "t3.micro"
#   key_name                    = var.my-windows-keys
#   subnet_id                   = module.vpc.public_subnets[0]
#   vpc_security_group_ids      = [aws_security_group.firs_windows_image_sg.id]
#   associate_public_ip_address = true

#   tags = {
#     Name = "WindowsAMIBase"
#   }
# }

# resource "aws_ami_from_instance" "windows_ami" {
#   name               = "firs_image_ami"
#   source_instance_id = aws_instance.firs_windows_image_instance.id
#   #depends_on         = [aws_instance.firs-windows_image_instance]
# }