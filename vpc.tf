# Configure the AWS provider and set the region
provider "aws" {
  region = "us-east-2"
}

# Input variables (defined elsewhere or passed via tfvars)
# These make the module reusable with different CIDR values
variable vpc_cidr_block {}
variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}

# Fetch the list of available Availability Zones in the selected region
# Used to distribute subnets across zones for high availability
data "aws_availability_zones" "available" {}

# Use the official Terraform AWS VPC module from the registry
# This abstracts away the manual steps of writing VPC resources from scratch
module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"  # Locking to a specific version for stability

  # General VPC settings
  name             = "myapp-vpc"                          # Name prefix for the VPC and resources
  cidr             = var.vpc_cidr_block                   # The main CIDR block for the VPC
  private_subnets  = var.private_subnet_cidr_blocks       # List of CIDRs for private subnets
  public_subnets   = var.public_subnet_cidr_blocks        # List of CIDRs for public subnets
  azs              = data.aws_availability_zones.available.names  # Use available AZs for subnet distribution

  # Enable NAT Gateway for internet access from private subnets
  enable_nat_gateway = true
  single_nat_gateway = true  # Use a single NAT gateway for all AZs (cost-effective)

  # Enable DNS hostnames in the VPC (required for services like EKS)
  enable_dns_hostnames = true

  # Global tags for all resources created by the module
  # Helps Kubernetes/EKS recognize and manage the infrastructure
  tags = {
    "kubernetes.io/cluster/app-eks-cluster" = "shared"
  }

  # Specific tags for public subnets
  # Marks them as usable by Kubernetes LoadBalancers (e.g., for services)
  public_subnet_tags = {
    "kubernetes.io/cluster/app-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                = 1  # External Load Balancers
  }

  # Specific tags for private subnets
  # Marks them as usable for internal LoadBalancers (inside the VPC)
  private_subnet_tags = {
    "kubernetes.io/cluster/app-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"       = 1  # Internal Load Balancers
  }
}
