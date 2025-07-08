variable "environment" {
  description = "The name of the environment (e.g., dev, prod)."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the compute resources will be deployed."
  type        = string

}

variable "cluster_name" {
  description = "The name of the environment cluster"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to deploy instances into."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "The kubernetes version to use for the EKS cluster."
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to attach to the instances."
  type        = list(string)
}

variable "admin_iam_role_arns" {
  description = "A list of IAM Role ARNs that should be granted cluster-admin access via EKS Access Entries. Max 1 for simplicity in this example."
  type        = list(string)
}

variable "default_tags" {
  description = "A map of default tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "subnets" {
  description = "A map defining the VPC subnets with their CIDR, type, and AZ."
  type = map(object({
    cidr_block              = string
    type                    = string # "public" or "private"
    availability_zone       = string
    map_public_ip_on_launch = optional(bool, false) # For public subnets
  }))
}

variable "create_nat_gateway" {
  description = "Boolean to control if a NAT Gateway should be created."
  type        = bool
  default     = true
}

variable "dev_ssh_ingress_cidrs" {
  description = "List of CIDR blocks that are allowed to SSH into resources using the default SG."
  type        = list(string)
}

variable "dev_web_ingress_cidrs" {
  description = "List of CIDR blocks that are allowed HTTP/HTTPS access into resources using the default SG."
  type        = list(string)
}

variable "default_tags" {
  description = "A map of default tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}