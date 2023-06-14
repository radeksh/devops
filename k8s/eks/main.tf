terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0.1"
        }
    }
}

provider "aws" {
    access_key = var.aws_access_id
    secret_key = var.aws_access_key
    region     = "eu-central-1"
}

variable "aws_access_id" {}

variable "aws_access_key" {}

resource "aws_vpc" "eks_cluster_vpc" {
  cidr_block = "10.99.0.0/16"
}

resource "aws_subnet" "eks_cluster_subnet_eu-central-1" {
  vpc_id     = aws_vpc.eks_cluster_vpc.id
  cidr_block = "10.99.1.0/24"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "eks_cluster_subnet_eu-central-2" {
  vpc_id     = aws_vpc.eks_cluster_vpc.id
  cidr_block = "10.99.2.0/24"
  availability_zone = "eu-central-1b"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks_cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.eks_cluster_subnet_eu-central-1.id,
      aws_subnet.eks_cluster_subnet_eu-central-2.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_policy-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks_node_group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids = [
    aws_subnet.eks_cluster_subnet_eu-central-1.id,
    aws_subnet.eks_cluster_subnet_eu-central-2.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_group-AmazonEC2ContainerRegistryReadOnly,
  ]
}


output "endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}
