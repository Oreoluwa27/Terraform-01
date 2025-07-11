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

#Network Module for the Dev Environment
module "network" {
  source             = "../../modules/network"
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  subnets            = var.subnets
  create_nat_gateway = var.create_nat_gateway

  ssh_ingress_cidrs = var.dev_ssh_ingress_cidrs
  web_ingress_cidrs = var.dev_web_ingress_cidrs

  default_tags = var.default_tags
}

#Compute Module for the Dev Environment
module "compute" {
  source              = "../../modules/compute" 
  environment         = var.environment
  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  admin_iam_role_arns = var.admin_iam_role_arns
  vpc_id              = module.network.vpc_id
  subnet_ids          = values(module.network.public_subnet_ids)


  security_group_ids = [module.network.default_security_group_id]

  default_tags = var.default_tags
}

#temporary database instance for dev environment
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Adminpassword2004!"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible = true
}