data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_subnet" "devops_public_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = var.vpc_id
  cidr_block              = "10.218.1${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "devops-public-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_subnet" "devops_private_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = var.vpc_id
  cidr_block              = "10.218.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "devops-private-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

//resource "aws_subnet" "devops_private_subnet_a" {
//  vpc_id     = var.vpc_id
//  cidr_block = var.private_subnet_za_ip
//  availability_zone = var.avail_zone_a
//  tags = {
//    Name = "devops_private_subnet_a"
//  }
//}
//
//resource "aws_subnet" "devops_private_subnet_b" {
//  vpc_id     = var.vpc_id
//  cidr_block = var.private_subnet_zb_ip
//  availability_zone = var.avail_zone_b
//  tags = {
//    Name = "devops_private_subnet_b"
//  }
//}
//
//resource "aws_subnet" "devops_public_subnet_a" {
//  vpc_id     = var.vpc_id
//  cidr_block = var.public_subnet_za_ip
//  availability_zone = var.avail_zone_a
//  tags = {
//    Name = "devops_public_subnet_a"
//  }
//}
//
//resource "aws_subnet" "devops_public_subnet_b" {
//  vpc_id     = var.vpc_id
//  cidr_block = var.public_subnet_zb_ip
//  availability_zone = var.avail_zone_b
//  tags = {
//    Name = "devops_public_subnet_b"
//  }
//}

resource "aws_internet_gateway" "devops-igw" {
    vpc_id = var.vpc_id
    tags   = {
        Name = "${var.env_prefix}-igw"
    }
}

resource "aws_eip" "allocation-ngw" {
  vpc = true
}

resource "aws_nat_gateway" "devops-ngw" {
  allocation_id = aws_eip.allocation-ngw.id
  subnet_id = aws_subnet.devops_public_subnet[0].id
  tags = {
    "Name" = "devops-natgateway"
  }
}

resource "aws_route_table" "devops_public_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops-igw.id
  }
  tags = {
    "Name" = "devops_public_rt"
  }
}

resource "aws_route_table_association" "associate_devops_public_subnet" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id = aws_subnet.devops_public_subnet[count.index].id
  route_table_id = aws_route_table.devops_public_rt.id
}



resource "aws_route_table" "devops_private_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.devops-ngw.id
  }
  tags = {
    "Name" = "devops_private_rt"
  }
}

resource "aws_route_table_association" "associate_devops_private_subnet" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id = aws_subnet.devops_private_subnet[count.index].id
  route_table_id = aws_route_table.devops_private_rt.id
}





