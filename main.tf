provider "aws" {
  region = "us-west-2" 
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-0c55b159cbfafe1f0" 
  instance_type = "t2.micro"
  key_name      = "dharan-a9" 

  # Enable SSH access
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  tags = {
    Name = "Ansible-EC2"
  }
}

resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Local file to generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = <<EOF
[web]
${aws_instance.my_ec2.private_ip}
EOF
  filename = "${path.module}/inventory.ini"
}

output "instance_ip" {
  value = aws_instance.my_ec2.private_ip
}
