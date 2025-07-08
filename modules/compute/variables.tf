# modules/compute/variables.tf

variable "environment" {
  description = "The environment for which the compute resources are being created (e.g., dev, staging, prod)."
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