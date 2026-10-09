resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "sub1" {
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.myvpc.id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.myvpc.id
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id
  region = "us-east-1"
}

resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_security_group" "sg" {
  name   = "microservices-security-group"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "url service"
    from_port   = 80
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "analytics service"
    from_port   = 80
    to_port     = 6001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_nat_gateway" "nat1" {
  vpc_id    = aws_vpc.myvpc.id
  subnet_id = aws_subnet.sub1.id
}

resource "aws_nat_gateway" "nat2" {
  vpc_id    = aws_vpc.myvpc.id
  subnet_id = aws_subnet.sub2.id
}

resource "aws_instance" "server1" {
  ami = "ami-0b6d9d3d33ba97d99"
  instance_type          = "t2.micro"
  security_groups = [aws_security_group.sg.id]
  subnet_id = aws_subnet.sub1.id
}

resource "aws_instance" "server2" {
  ami = "ami-0b6d9d3d33ba97d99"
  instance_type          = "t2.micro"
  security_groups = [aws_security_group.sg.id]
  subnet_id = aws_subnet.sub2.id
}

resource "aws_lb" "mylb" {
  name = "micro-service-lb"
  internal = false 
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg.id]
  subnets = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

resource "aws_lb_target_group" "tg" {
  name = "dicroservices-target-group"
  port = 80
  protocol = "http"
  vpc_id = aws_vpc.myvpc.id 

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.server1.id
  port = 3000
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.server1.id
  port = 3000
}

resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}
