resource "aws_internet_gateway" "igw" {
  count = length(var.azs) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      "Name" = format("%s", var.name)
    }
  )
}

resource "aws_route_table" "public" {
  count = length(var.azs) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[count.index].id
  }

  tags = merge(
    {
      "Name" = format("%s-public", var.name)
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.azs) > 0 ? length(var.azs) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

##############
# NAT Gateway
##############
locals {
  nat_gateway_count = 1
  nat_gateway_ips = split(
    ",", join(",", aws_eip.nat_eip.*.id),
  )
}

resource "aws_eip" "nat_eip" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, count.index),
      )
    }
  )
}

resource "aws_nat_gateway" "nat" {
  count = local.nat_gateway_count

  allocation_id = element(
    local.nat_gateway_ips,
    count.index,
  )
  subnet_id = element(
    aws_subnet.public.*.id,
    count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, count.index),
      )
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  count = length(var.azs) > 0 ? length(var.azs) : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      "Name" = format("%s-private-%s", var.name, element(var.azs, count.index),
      )
    }
  )

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = [propagating_vgws]
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.azs) > 0 ? length(var.azs) : 0

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_security_group" "sg" {
  name        = "sg"
  vpc_id      = aws_vpc.main.id

  ingress {    
    description = "web port"
    from_port   = 80    
    to_port     = 80
    protocol    = "tcp"    
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh port"
    from_port   = 22    
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "monitoring"
    from_port   = 9100    
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}

