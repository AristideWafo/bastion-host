output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "private_instance_ip" {
  description = "Private IP address of the private EC2 instance"
  value       = aws_instance.private.private_ip
}

output "private_instance_id" {
  description = "Instance ID of the private EC2 instance"
  value       = aws_instance.private.id
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.main.key_name
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key (if auto-generated)"
  value       = var.ssh_public_key == "" ? "${path.module}/../.ssh/${var.project_name}-key.pem" : "Using provided key"
}

output "ssh_command_bastion" {
  description = "Command to SSH into bastion host"
  value       = "ssh -i ${var.ssh_public_key == "" ? "${path.module}/../.ssh/${var.project_name}-key.pem" : "your-key.pem"} ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_command_private_via_bastion" {
  description = "Command to SSH into private instance via bastion"
  value       = "ssh -i ${var.ssh_public_key == "" ? "${path.module}/../.ssh/${var.project_name}-key.pem" : "your-key.pem"} -o ProxyCommand='ssh -i ${var.ssh_public_key == "" ? "${path.module}/../.ssh/${var.project_name}-key.pem" : "your-key.pem"} -W %h:%p ec2-user@${aws_instance.bastion.public_ip}' ec2-user@${aws_instance.private.private_ip}"
}
