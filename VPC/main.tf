locals {
  tags = {
    Environment = Dev
  }
}

resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "New_VPC"
  }
}

resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  default_tags = merge(local.tags, {
  Name = "Web-1a",
  })

}

resource "aws_subnet" "web-subnet-2" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  default_tags = merge(local.tags, {
  Name = "Web-2a",
  })
}

resource "aws_subnet" "application-subnet-1" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  default_tags = merge(local.tags, {
  Name = "Application-1a",
  })
}

resource "aws_subnet" "application-subnet-2" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  default_tags = merge(local.tags, {
  Name = "Application-2a",
  })
}

resource "aws_subnet" "database-subnet-1" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1a"
  default_tags = merge(local.tags, {
  Name = "Database-1a",
  })

}

resource "aws_subnet" "database-subnet-2" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "us-east-1b"

   default_tags = merge(local.tags, {
  Name = "Database-2a",
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev.id

  default_tags = merge(local.tags, {
  Name = "IGW",
  })
}

resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  default_tags = merge(local.tags, {
    Name = "WebRT"
  })
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-subnet-1.id
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-subnet-2.id
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_instance" "webserver1" {
  ami                    = "var.AMI_ID"
  instance_type          = "var.INSTANCE_TYPE"
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-1.id

  default_tags = merge(local.tags, {
    Name = "Web Server1"
  })
}

resource "aws_instance" "webserver2" {
  ami                    = "var.AMI_ID"
  instance_type          = "var.INSTANCE_TYPE"
  availability_zone      = "us-east-1b"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-2.id

  default_tags = merge(local.tags, {
    Name = "Web Server2"
  })
}

resource "aws_security_group" "web-sg" {
  name        = "Web-SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.dev.id

  ingress {
    description = "HTTP from VPC"
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

  default_tags = merge(local.tags, {
    Name = "Web-SG"
  })
}

resource "aws_security_group" "webserver-sg" {
  name        = "Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.dev.id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  default_tags = merge(local.tags, {
    Name = "Webserver-SG"
  })
}

resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.dev.id

  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 3306 #mysql
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver-sg.id]
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  default_tags = merge(local.tags, {
    Name = "Database-SG"
  })
}

resource "aws_lb" "external-elb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}

resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.dev.id
}

resource "aws_lb_target_group_attachment" "external-elb1" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver1.id
  port             = 80

  depends_on = [
    aws_instance.webserver1,
  ]
}

resource "aws_lb_target_group_attachment" "external-elb2" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver2.id
  port             = 80

  depends_on = [
    aws_instance.webserver2,
  ]
}

resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 100
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "mysql"
  engine_version         = "8.0.20"
  instance_class         = "db.t2.micro"
  multi_az               = true
  name                   = "mydb"
  username               = "var.UserName"
  password               = "var.PWD"
  vpc_security_group_ids = [aws_security_group.database-sg.id]
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.database-subnet-1.id, aws_subnet.database-subnet-2.id]

  default_tags = merge(local.tags, {
    Name = "My DB subnet group"
  })
}

