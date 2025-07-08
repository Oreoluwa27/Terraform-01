# environments/dev/main.tf

terraform {
  required_version = ">= 1.3.0"
  required_providers {


    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = "eu-north-1"
}


# 1. Call the Network Module for the Dev Environment
module "network" {
  source             = "../../modules/network"
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  subnets            = var.subnets
  create_nat_gateway = var.create_nat_gateway

  # Ingress rules for dev can be more permissive for easier testing
  ssh_ingress_cidrs = var.dev_ssh_ingress_cidrs
  web_ingress_cidrs = var.dev_web_ingress_cidrs

  default_tags = var.default_tags
}

# 2. Call the Compute Module for the Dev Environment
module "compute" {
  source              = "../../modules/compute" # Path to your compute module
  environment         = var.environment
  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  admin_iam_role_arns = var.admin_iam_role_arns
  vpc_id              = module.network.vpc_id
  subnet_ids          = values(module.network.public_subnet_ids)


  security_group_ids = [module.network.default_security_group_id]

  default_tags = var.default_tags
}

