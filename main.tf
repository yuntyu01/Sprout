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

#################
### routtable ###
#################
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

##############
### subnet ###
##############

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

################
### instance ###
################
resource "aws_instance" "prod_was_a" {
  ami           = "ami-077ad873396d76f6a"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.prod_was_sg.id]

  subnet_id = aws_subnet.prod_was_a.id
  key_name  = "prod_key"

  tags = {
    Name = "prod_was_a"
  }
}
resource "aws_instance" "prod_was_c" {
  ami           = "ami-077ad873396d76f6a"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.prod_was_sg.id]

  subnet_id = aws_subnet.prod_was_c.id
  key_name  = "prod_key"

  tags = {
    Name = "prod_was_c"
  }
}

resource "aws_security_group" "prod_was_sg" {
  name        = "prod-was-sg"
  description = "Security group for WAS servers"
  vpc_id      = aws_vpc.prod.id

  # 인바운드 규칙: ALB에서 오는 HTTP 허용
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description     = "Allow HTTP from anywhere"
  }

    ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description     = "Allow SSH from anywhere"
  }
  
  

  # 아웃바운드 규칙: 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "prod-was-sg"
  }
}

########################
### ALB, TargetGroup ### 
########################

resource "aws_lb" "prod_lb" {
  name               = "prod-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.prod_alb_sg.id]
  subnets            = [aws_subnet.prod_pub_a.id, aws_subnet.prod_pub_c.id]


  tags = {
    Environment = "prod"
  }
}


resource "aws_lb_listener" "prod_listener" {
  load_balancer_arn = aws_lb.prod_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_was_tg.arn
  }
}

resource "aws_lb_target_group" "prod_was_tg" {
  name     = "prod-was-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "prod_was_tg"
  }
}

resource "aws_lb_target_group_attachment" "prod_was_a_attach" {
  target_group_arn = aws_lb_target_group.prod_was_tg.arn
  target_id        = aws_instance.prod_was_a.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "prod_was_c_attach" {
  target_group_arn = aws_lb_target_group.prod_was_tg.arn
  target_id        = aws_instance.prod_was_c.id
  port             = 80
}

resource "aws_security_group" "prod_alb_sg" {
  name        = "prod-alb-sg"
  description = "Security group for public ALB"
  vpc_id      = aws_vpc.prod.id

  # 인바운드 규칙: 외부 HTTP/HTTPS 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # 아웃바운드 규칙: 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "prod-alb-sg"
  }
}