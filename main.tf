terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}

# Create a VPC
resource "aws_vpc" "prod" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prod_vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "prod_igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod_public_rt"
  }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.prod_pub_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_c" {
  subnet_id      = aws_subnet.prod_pub_c.id
  route_table_id = aws_route_table.public.id
}
resource "aws_subnet" "prod_pub_a" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "prod_pub_a"
  }
}
resource "aws_subnet" "prod_pub_c" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "prod_pub_c"
  }
}

resource "aws_subnet" "prod_was_a" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "prod_was_a"
  }
}

resource "aws_subnet" "prod_db_a" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "prod_db_a"
  }
}

resource "aws_subnet" "prod_was_c" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "prod_was_c"
  }
}


resource "aws_subnet" "prod_db_c" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "prod_db_c"
  }
}


resource "aws_instance" "prod_was_a" {
  ami           = "ami-077ad873396d76f6a"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.prod_was_a.id
  key_name  = "prod_key"

  tags = {
    Name = "prod_was_a"
  }
}
resource "aws_instance" "prod_was_c" {
  ami           = "ami-077ad873396d76f6a"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.prod_was_c.id
  key_name  = "prod_key"

  tags = {
    Name = "prod_was_c"
  }
}
