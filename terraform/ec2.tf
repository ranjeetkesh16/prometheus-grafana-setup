# Configure AWS Provider
provider "aws" {
  region = "ap-south-1" # Change to your preferred region
}

# Monitor Node (Prometheus + Grafana)
resource "aws_instance" "monitor" {
  ami                    = "ami-0f559c3642608c138"
  instance_type          = "m7i-flex.large"
  count                  = 1
  key_name               = "Pathnex-ec2-key"  # Change according to your pem file
  subnet_id              = "subnet-060e30fbb2ffaa857" # Change according to your subnet
  vpc_security_group_ids = ["sg-006c76c984d9e1309"]   # Change according to your SG

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "monitor-node"
    Role = "monitor"
  }
}

# Target Nodes (where CPU spike will run)
resource "aws_instance" "targets" {
  ami                    = "ami-0f559c3642608c138"
  instance_type          = "t3.micro"
  count                  = 2
  key_name               = "Pathnex-ec2-key"  # Change according to your pem file
  subnet_id              = "subnet-060e30fbb2ffaa857" # Change according to your subnet
  vpc_security_group_ids = ["sg-006c76c984d9e1309"]   # Change according to your SG

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "target-node-${count.index}"
    Role = "target"
  }
}

output "monitor_ip" {
  value = aws_instance.monitor[0].public_ip
}

output "target_ips" {
  value = aws_instance.targets[*].public_ip
}

output "target_private_ips" {
  value = aws_instance.targets[*].private_ip
}
