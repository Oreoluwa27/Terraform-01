# environments/dev/dev.tfvars

environment         = "dev"
cluster_name        = "Osiris"
kubernetes_version  = "1.33"
admin_iam_role_arns = ["arn:aws:iam::974085360964:user/Oreoluwa", "arn:aws:iam::974085360964:user/github-user"]


# VPC Configuration
vpc_cidr = "10.61.0.0/16"
subnets = {
  "public-osiris-a" = {
    cidr_block              = "10.61.1.0/24"
    type                    = "public"
    availability_zone       = "eu-north-1a"
    map_public_ip_on_launch = true
  },
  "private-osiris-a" = {
    cidr_block              = "10.61.2.0/24"
    type                    = "private"
    availability_zone       = "eu-north-1b"
    map_public_ip_on_launch = false
  },
}
create_nat_gateway = false

# Security Group Ingress CIDRs (more permissive for dev)
dev_ssh_ingress_cidrs = ["0.0.0.0/0"]
dev_web_ingress_cidrs = ["0.0.0.0/0"]


# Default Tags
default_tags = {
  Project     = "E2E Terraform Learning"
  ManagedBy   = "Terraform"
  Environment = "dev"
}