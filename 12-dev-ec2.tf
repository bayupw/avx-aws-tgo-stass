# ---------------------------------------------------------------------------------------------------------------------
# dev banking ec2
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "dev_banking_instance_sg" {
  count       = var.create_ec2 ? 1 : 0
  name        = "stass-dev-banking/sg-instance"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = module.dev_banking_vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.ingress_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "stass-dev-banking/sg-instance"
  }
}

resource "aws_instance" "dev_banking_instance" {
  count                       = var.create_ec2 ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_size
  key_name                    = var.key_name == null ? aws_key_pair.instance_key_pair[0].key_name : var.key_name
  subnet_id                   = module.dev_banking_vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.dev_banking_instance_sg[0].id]
  associate_public_ip_address = true

  tags = {
    Name = "stass-dev-banking-instance"
  }
}

resource "aws_instance" "dev_banking_private_instance" {
  count                       = var.create_ec2 ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_size
  key_name                    = var.key_name == null ? aws_key_pair.instance_key_pair[0].key_name : var.key_name
  subnet_id                   = module.dev_banking_vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.dev_banking_instance_sg[0].id]
  associate_public_ip_address = false

  user_data = <<EOF
#!/bin/bash
sudo sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sudo systemctl restart sshd
echo ${var.instance_username}:${var.instance_password} | sudo chpasswd
EOF

  tags = {
    Name = "stass-dev-banking-private-instance"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# dev it service ec2
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "dev_it_service_instance_sg" {
  count       = var.create_ec2 ? 1 : 0
  name        = "stass-dev-spoke2/sg-instance"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = module.dev_it_service_vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.ingress_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "stass-dev-it-service/sg-instance"
  }
}

resource "aws_instance" "dev_it_service_instance" {
  count                       = var.create_ec2 ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_size
  key_name                    = var.key_name == null ? aws_key_pair.instance_key_pair[0].key_name : var.key_name
  subnet_id                   = module.dev_it_service_vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.dev_it_service_instance_sg[0].id]
  associate_public_ip_address = true

  tags = {
    Name = "stass-dev-it-service-instance"
  }
}

resource "aws_instance" "dev_it_service_private_instance" {
  count                       = var.create_ec2 ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_size
  key_name                    = var.key_name == null ? aws_key_pair.instance_key_pair[0].key_name : var.key_name
  subnet_id                   = module.dev_it_service_vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.dev_it_service_instance_sg[0].id]
  associate_public_ip_address = false


  user_data = <<EOF
#!/bin/bash
sudo sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sudo systemctl restart sshd
echo ${var.instance_username}:${var.instance_password} | sudo chpasswd
EOF

  tags = {
    Name = "stass-dev-it-service-private-instance"
  }
}
