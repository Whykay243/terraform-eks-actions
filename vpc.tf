# AWS provider configuration
provider "aws" {
  region = "us-east-1"
}

# Input variables
variable vpc_cidr_block {}
variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}

# Get available Availability Zones
data "aws_availability_zones" "available" {}

# VPC module from the Terraform AWS registry
module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name             = "myapp-vpc"
  cidr             = var.vpc_cidr_block
  private_subnets  = var.private_subnet_cidr_blocks
  public_subnets   = var.public_subnet_cidr_blocks
  azs              = data.aws_availability_zones.available.names

  enable_nat_gateway   = true         # Allow private subnets internet access
  single_nat_gateway   = true         # Use a single NAT to save cost
  enable_dns_hostnames = true         # Required for services like EKS

  tags = {
    "kubernetes.io/cluster/app-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/app-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/app-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"       = 1
  }
}
