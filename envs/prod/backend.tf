terraform {
  backend "s3" {
    bucket = "terraform-state-storage-974085360964"
    key    = "prod/terraform.tfstate"
    region = "eu-north-1"
    use_lockfile = true
    
  }
}

