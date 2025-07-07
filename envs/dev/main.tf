# environments/dev/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


# 1. Call the Network Module for the Dev Environment
module "network" {
  source      = "../../modules/network" # Path to your network module
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  subnets     = var.subnets
  create_nat_gateway = var.create_nat_gateway # Dev might not need NAT gateway for cost savings

  # Ingress rules for dev can be more permissive for easier testing
  ssh_ingress_cidrs = var.dev_ssh_ingress_cidrs
  web_ingress_cidrs = var.dev_web_ingress_cidrs

  default_tags = var.default_tags
}

# 2. Call the Compute Module for the Dev Environment
module "app_servers" {
  source      = "../../modules/compute" # Path to your compute module
  environment = var.environment
  app_name    = var.app_name

  instance_count = var.instance_count_dev
  ami_id         = var.ami_id_dev
  instance_type  = var.instance_type_dev
  key_pair_name  = var.key_pair_name # Shared key pair for now, could be env specific

  vpc_id             = module.network.vpc_id
  subnet_ids         = values(module.network.private_subnet_ids) # Deploy in private subnets
  security_group_ids = [module.network.default_security_group_id] # Attach default SG

  default_tags = var.default_tags
}

# Output some important details for quick access
output "dev_vpc_id" {
  value = module.network.vpc_id
}

output "dev_app_instance_public_ips" {
  value = module.app_servers.instance_public_ips
}

output "dev_app_instance_private_ips" {
  value = module.app_servers.instance_private_ips
}