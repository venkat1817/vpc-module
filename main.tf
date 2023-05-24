#create the vpc 
/* resource vpc 
resource igw 
resource attach 
resource subnets 
resource route table
resource eip 
resource nat_gateway/eip
resource associate routtable */

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "custom" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.envname
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom.id
  tags = {
    Name = var.envname
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.custom.id
  cidr_block              = element(var.public_subnet_cidr, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = "true"
  tags = {
    Name = "${var.envname}-public-subnet-${count.index+1}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.custom.id
  cidr_block        = element(var.private_subnet_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${var.envname}-private-subnet${count.index+1}"
  }
}

resource "aws_subnet" "data" {
  count             = length(var.data_subnet_cidr)
  vpc_id            = aws_vpc.custom.id
  cidr_block        = element(var.data_subnet_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${var.envname}-data-subnet${count.index+1}"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = var.envname
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = var.envname
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.envname}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.envname}-private"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data" {
  count          = length(var.data_subnet_cidr)
  subnet_id      = element(aws_subnet.data.*.id, count.index)
  route_table_id = aws_route_table.private.id
}