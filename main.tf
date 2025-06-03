terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
  access_key = ""
  secret_key = ""
}

resource "aws_instance" "nginx_server" {
    ami           = "ami-0c1ac8a41498c1a9c" # Example AMI ID, replace with a valid one for your region
    instance_type = "t2.micro"

    tags = {
        Name = "NginxServer"
    }
}


##syntax for terraform resource
## resource <provider>_<resource_type> <resource_name> {
#   <argument> = <value>
#   <argument> = <value>
#}