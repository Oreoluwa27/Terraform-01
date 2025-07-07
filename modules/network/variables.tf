# modules/network/variables.tf

variable "environment" {
  description = "The name of the environment (e.g., dev, prod)."
  type        = string
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

variable "ssh_ingress_cidrs" {
  description = "List of CIDR blocks that are allowed to SSH into resources using the default SG."
  type        = list(string)
}

variable "web_ingress_cidrs" {
  description = "List of CIDR blocks that are allowed HTTP/HTTPS access into resources using the default SG."
  type        = list(string)
}

variable "default_tags" {
  description = "A map of default tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}