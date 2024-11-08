provider "aws" {
  region = "us-west-2" 
}

# IAM Role for EC2 with SSM and CloudWatch Permissions
resource "aws_iam_role" "ec2_role" {
  name = "ec2_ssm_cloudwatch_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

# IAM Policy with permissions for SSM and CloudWatch logging
resource "aws_iam_policy" "ec2_ssm_cloudwatch_policy" {
  name        = "ec2_ssm_cloudwatch_policy"
  description = "Policy for SSM and CloudWatch access"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenDataChannel",
          "ssmmessages:OpenControlChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource": "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ssm_cloudwatch_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_ssm_cloudwatch_policy.arn
}

# Create an Instance Profile for the role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 instance with IAM instance profile for SSM and CloudWatch
resource "aws_instance" "my_ec2" {
  ami                    = "ami-04dd23e62ed049936" # Replace with your AMI ID
  instance_type          = "t2.micro"
  key_name               = "dharan-ansible" 
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name # Attach IAM profile

  # Enable SSH access
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  tags = {
    Name = "Ansible-EC2"
  }
}

# Security Group to allow SSH
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

# Generate Ansible inventory file with the EC2 public IP
resource "local_file" "ansible_inventory" {
  content = <<EOF
[web]
${aws_instance.my_ec2.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./dharan-ansible.pem
EOF
  filename = "inventory.ini"
}

# Output the EC2 instance's public IP
output "instance_ip" {
  value = aws_instance.my_ec2.public_ip
}
