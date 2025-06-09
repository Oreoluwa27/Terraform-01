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

resource "aws_s3_bucket" "tf_state" {
  bucket = "terraform-state-storage-974085360964"

  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "Terraform State Bucket"
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

## This resource is used to create a DynamoDB table for state locking.
## It has been deprecated in favor of using s3 resource locking directly.
/* resource "aws_dynamodb_table" "tf_state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
  lifecycle {
    prevent_destroy = false
  }
} */
