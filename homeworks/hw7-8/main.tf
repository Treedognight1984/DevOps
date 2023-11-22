provider "aws" {
  region = "us-east-1" # Update this with your desired region
}

resource "aws_security_group" "jenkins_security_group" {
  name        = "launch-wizard-10"
  description = "Security group for Jenkins instances"

  # Allow SSH traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Jenkins Web Interface (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Jenkins Agent Port (50000)
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow WordPress (Port 8000)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "jenkins_master" {
  ami               = "ami-0fc5d935ebf8bc3bc"
  instance_type     = "t3.small"
  key_name          = "macbook"
  security_groups   = [aws_security_group.jenkins_security_group.name]

  tags = {
    Name = "Jenkins_Master"
  }
}

resource "aws_instance" "jenkins_slave" {
  ami               = "ami-0fc5d935ebf8bc3bc"
  instance_type     = "t3.small"
  key_name          = "macbook"
  security_groups   = [aws_security_group.jenkins_security_group.name]

  tags = {
    Name = "Jenkins_Slave"
  }
}

resource "aws_instance" "work_instance" {
  ami               = "ami-0fc5d935ebf8bc3bc"
  instance_type     = "t3.small"
  key_name          = "macbook"
  security_groups   = [aws_security_group.jenkins_security_group.name]

  tags = {
    Name = "Work_Instance"
  }
}