# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# SSH Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.main[0].public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

# Generate SSH key if not provided
resource "tls_private_key" "main" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally (only when auto-generated)
resource "local_file" "private_key" {
  count           = var.ssh_public_key == "" ? 1 : 0
  content         = tls_private_key.main[0].private_key_pem
  filename        = "${path.module}/../.ssh/${var.project_name}-key.pem"
  file_permission = "0600"
}

# Bastion Host (Public EC2 Instance)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.main.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y curl wget
              echo "Bastion host configured" > /tmp/bastion-ready
              EOF

  tags = {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
  }
}

# Private EC2 Instance
resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_instance.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y curl wget
              echo "Private instance configured" > /tmp/private-ready
              EOF

  tags = {
    Name = "${var.project_name}-private-instance"
    Role = "private"
  }
}
