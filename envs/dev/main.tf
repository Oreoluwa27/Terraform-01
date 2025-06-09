module "network" {
  source              = "../../modules/network"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.2.0/24"]
  tags = {
    Environment = "dev"
  }
}

module "compute" {
  source        = "../../modules/compute"
  instance_type = "t3.micro"
  subnet_id     = module.network.public_subnets[0]
  ami_id        = "ami-0abcdef1234567890"
  tags = {
    Environment = "dev"
  }
}

module "storage" {
  source      = "../../modules/storage"
  bucket_name = "dev-app-storage"
}
