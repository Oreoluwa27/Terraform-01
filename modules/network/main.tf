
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = merge(var.tags, {
    Name = "${var.environment}"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.environment}-igw"
  })
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id 

  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.main.id 
  }


  tags = merge(var.tags, {
    Name = "${var.environment}-public-rtb" 
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # Example if using a NAT Gateway (uncomment and adjust as needed)
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   nat_gateway_id = aws_nat_gateway.example.id # Replace with your NAT Gateway resource
  # }

  tags = merge(var.tags, {
    Name = "${var.environment}-private-rtb" 
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  cidr_block        = var.private_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  tags = merge(var.tags, {
    Name = "${var.environment}-private-subnet-${count.index}"
  })
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  cidr_block        = var.public_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true 
  tags = merge(var.tags, {
    Name = "${var.environment}-public-subnet-${count.index}"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "sample_sg" {
  name        = "${var.environment}-${var.resource_group}-sg"
  description = "Security group for ${var.resource_group} resources in ${var.environment} environment"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.environment}-public-sg"
  })
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.sample_sg.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.sample_sg.id
}
