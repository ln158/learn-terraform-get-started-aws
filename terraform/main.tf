# test change
terraform {
  # This is the "Backend" block you were missing
  backend "s3" {
    bucket  = "lina-terraform-state-london-2026" # The bucket you just made
    key     = "lina/terraform.tfstate"           # The name of the state file
    region  = "eu-west-2"                        # London
#    profile = "lina-terraform"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
#  profile = "lina-terraform"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "terraform_test_sg" {
  name        = "lina-terraform-test-sg"
  description = "Security group for Terraform EC2 test"
  vpc_id      = "vpc-07767cc02dc1b01d7"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "lina-terraform-test-sg"
    owner = "lina"
  }
}

resource "aws_instance" "terraform_test_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = "subnet-0191d68a21c0ca0cc"
  vpc_security_group_ids = [aws_security_group.terraform_test_sg.id]

  tags = {
    Name  = "lina-terraform-instance-test"
    owner = "lina"
  }
}

# --- ECR Repository for Task App ---
resource "aws_ecr_repository" "task_app_repo" {
  name                 = "lina-task-app-repo" # The name of your "Storage Folder" in ECR
  image_tag_mutability = "MUTABLE"            # Allows you to push updates to the same tag (like 'latest')

  image_scanning_configuration {
    scan_on_push = true # Automatically checks your code for security vulnerabilities when you push
  }

  tags = {
    Name  = "lina-task-app-repo"
    owner = "lina"
  }
}

# --- Output the URL ---
# This helps you know where to push your images later
output "ecr_repository_url" {
  value       = aws_ecr_repository.task_app_repo.repository_url
  description = "The URL of the ECR repository"
}

