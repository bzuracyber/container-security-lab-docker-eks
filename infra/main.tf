terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"   # pick a stable 5.x release
    }
  }
}

provider "aws" {
  region = var.region
}

# ECR for your app image
resource "aws_ecr_repository" "app" {
  name                 = "lab-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Minimal VPC with two public subnets
resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "lab-vpc" }
}

resource "aws_subnet" "lab_a" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = { Name = "lab-subnet-a" }
}

resource "aws_subnet" "lab_b" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = { Name = "lab-subnet-b" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.lab_a.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.lab_b.id
  route_table_id = aws_route_table.rt.id
}

# EKS cluster with managed node group
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"   # stable v20 release

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = aws_vpc.lab.id
  subnet_ids = [aws_subnet.lab_a.id, aws_subnet.lab_b.id]

  enable_irsa = true

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.micro"]
      desired_size   = 2
      min_size       = 1
      max_size       = 2
    }
  }
    access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::513689972854:user/bzuracyberlab"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
            namespaces = []
          }
        }
      }
    }
  }
}