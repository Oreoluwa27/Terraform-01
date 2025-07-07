# 1. AWS VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.default_tags, {
    Name = "${var.environment}-vpc"
  })
}

# 2. Internet Gateway (for Public Subnets to access the internet)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.default_tags, {
    Name = "${var.environment}-igw"
  })
}

# 3. Subnets (using for_each for flexibility and stability)
# Filter input subnets into public and private for easier processing
locals {
  public_subnets_config  = { for k, v in var.subnets : k => v if v.type == "public" }
  private_subnets_config = { for k, v in var.subnets : k => v if v.type == "private" }
  # Filter only the first public subnet to place NAT Gateway
  first_public_subnet_id = length(aws_subnet.public) > 0 ? tolist(aws_subnet.public)[0].id : null
}

resource "aws_subnet" "public" {
  for_each                = local.public_subnets_config
  cidr_block              = each.value.cidr_block
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.availability_zone
  # Auto-assign public IPs to instances launched in these subnets
  map_public_ip_on_launch = each.value.map_public_ip_on_launch # Use optional flag
  tags = merge(var.default_tags, {
    Name = "${var.environment}-${each.key}"
  })
}

resource "aws_subnet" "private" {
  for_each          = local.private_subnets_config
  cidr_block        = each.value.cidr_block
  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.availability_zone
  tags = merge(var.default_tags, {
    Name = "${var.environment}-${each.key}"
  })
}

# 4. Elastic IP for NAT Gateway (required for NAT Gateway)
resource "aws_eip" "nat_gateway_eip" {
  count = var.create_nat_gateway ? 1 : 0 # Only create if enabled
  domain = "vpc" 
  tags = merge(var.default_tags, {
    Name = "${var.environment}-nat-gateway-eip"
  })
}

# 5. NAT Gateway (for Private Subnets to access the internet outbound)
# Placed in the first public subnet
resource "aws_nat_gateway" "main" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_gateway_eip[0].id
  subnet_id     = local.first_public_subnet_id
  tags = merge(var.default_tags, {
    Name = "${var.environment}-nat-gateway"
  })
  # Ensure the NAT Gateway is created after its dependencies
  depends_on = [aws_internet_gateway.main]
}

# 6. Public Route Table
# Routes 0.0.0.0/0 (all IPv4 internet traffic) to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.default_tags, {
    Name = "${var.environment}-public-rtb"
  })
}

# 7. Private Route Table
# Routes 0.0.0.0/0 (all IPv4 internet traffic) to the NAT Gateway (if enabled)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.create_nat_gateway ? [1] : [] # Only create this route if NAT is enabled
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.default_tags, {
    Name = "${var.environment}-private-rtb"
  })
}

# 8. Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# 9. Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# 10. Default Security Group (for general purpose)
# This SG can be attached to various resources within this VPC
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group for ${var.environment} environment"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.default_tags, {
    Name = "${var.environment}-default-sg"
  })
}

# 11. Security Group Rule: Ingress for SSH from trusted IPs (e.g., bastion host or your office)
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_ingress_cidrs # Controlled by variable
  description       = "Allow SSH access"
  security_group_id = aws_security_group.default.id
}

# 12. Security Group Rule: Ingress for HTTP/HTTPS (if exposed publicly)
# Often, web servers would have their own dedicated SG, but this provides a common one.
resource "aws_security_group_rule" "http_https_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.web_ingress_cidrs # Controlled by variable
  description       = "Allow HTTP/HTTPS access"
  security_group_id = aws_security_group.default.id
}

# 13. Security Group Rule: Egress (Outbound traffic)
# By default, a security group allows all outbound traffic.
# Explicitly defining it can be good for auditing or if you need to restrict later.
resource "aws_security_group_rule" "all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # -1 means all protocols
  cidr_blocks       = ["0.0.0.0/0"] # Allow all outbound IPv4 traffic to internet
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.default.id
}