variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch instance in"
  type        = string
}

variable "ami_id" {
  description = "AMI to use"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
