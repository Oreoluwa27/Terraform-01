###note- all code in compute, network, and storage modules should be edited.


resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = merge(var.tags, {
    Name = "main-vpc"
  })
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  cidr_block        = var.public_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = "eu-north-1a" # Use a variable or data lookup in production
  tags = merge(var.tags, {
    Name = "public-subnet-${count.index}"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  cidr_block        = var.private_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = "eu-north-1b"
  tags = merge(var.tags, {
    Name = "private-subnet-${count.index}"
  })
}


#vpc
#subnet
#internet gateway
#route table
#NAT gateway ----- I dont advice it, put cluster in a public subnet ---- ask emmanuel
#security group
##network acl
