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
}

resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "sub1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_route_table_association" "sub2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_security_group" "alb-sg" {
  name   = "microservices-security-group-alb"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "url-service"
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "ec2-sg" {
  name   = "microservices-ec2-sg"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description     = "URL service traffic from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db-sg" {
  name   = "microservices-ec2-sg"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description     = "PostgreSQL from URL service servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2-sg.id]
  }

  ingress {
    description     = "Redis from URL service servers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2-sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_instance" "server1" {
  ami                  = "ami-0b6d9d3d33ba97d99"
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.ec2-sg.id]
  subnet_id            = aws_subnet.sub1.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
}

resource "aws_instance" "server2" {
  ami                  = "ami-0b6d9d3d33ba97d99"
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.ec2-sg.id]
  subnet_id            = aws_subnet.sub2.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
}

resource "aws_instance" "database-server" {
  ami                  = "ami-0b6d9d3d33ba97d99"
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.ec2-sg.id]
  subnet_id            = aws_subnet.sub1.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
}

resource "aws_volume_attachment" "db_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.db_data.id
  instance_id = aws_instance.database-server.id
}

resource "aws_lb" "mylb" {
  name               = "micro-service-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "microservices-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.server1.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.server1.id
  port             = 3000
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

resource "aws_ecr_repository" "ecr" {
  name                 = "microservices-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "ec2_ecr_role" {
  name = "url-service-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_pull" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "url-service-ec2-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

resource "aws_ebs_volume" "db_data" {
  availability_zone = aws_subnet.sub1.availability_zone
  size              = 10
  type              = "gp3"

  tags = {
    Name = "microservices-db-data"
  }

}