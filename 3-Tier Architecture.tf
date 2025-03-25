# main.tf
provider "aws" {
  region = "us-east-1"
}

# Variables
variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "web_instance_type" {
  description = "EC2 instance type for web tier"
  default     = "t2.micro"
}

variable "app_instance_type" {
  description = "EC2 instance type for app tier"
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  default     = "db.t2.micro"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# VPC
resource "aws_vpc" "three_tier_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Three-Tier-VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name = "Three-Tier-IGW"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "NAT-Gateway-EIP"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.web_subnet_1.id
  tags = {
    Name = "Three-Tier-NAT"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Subnets
# Web Tier (Public Subnets)
resource "aws_subnet" "web_subnet_1" {
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Web-Subnet-1"
    Tier = "Web"
  }
}

resource "aws_subnet" "web_subnet_2" {
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Web-Subnet-2"
    Tier = "Web"
  }
}

# App Tier (Private Subnets)
resource "aws_subnet" "app_subnet_1" {
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "App-Subnet-1"
    Tier = "Application"
  }
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "App-Subnet-2"
    Tier = "Application"
  }
}

# Database Tier (Private Subnets)
resource "aws_subnet" "db_subnet_1" {
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "DB-Subnet-1"
    Tier = "Database"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "DB-Subnet-2"
    Tier = "Database"
  }
}

# Route Tables
# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.three_tier_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public-Route-Table"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.three_tier_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "Private-Route-Table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.web_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.web_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.app_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.app_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_db_1" {
  subnet_id      = aws_subnet.db_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_db_2" {
  subnet_id      = aws_subnet.db_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups
# Web Tier Security Group
resource "aws_security_group" "web_sg" {
  name        = "web-tier-sg"
  description = "Allow HTTP/HTTPS and SSH traffic"
  vpc_id      = aws_vpc.three_tier_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
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
    Name = "Web-Tier-SG"
  }
}

# App Tier Security Group
resource "aws_security_group" "app_sg" {
  name        = "app-tier-sg"
  description = "Allow traffic from web tier and SSH"
  vpc_id      = aws_vpc.three_tier_vpc.id

  ingress {
    description     = "Allow traffic from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "SSH from web tier"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App-Tier-SG"
  }
}

# DB Tier Security Group
resource "aws_security_group" "db_sg" {
  name        = "db-tier-sg"
  description = "Allow traffic from app tier"
  vpc_id      = aws_vpc.three_tier_vpc.id

  ingress {
    description     = "Allow MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB-Tier-SG"
  }
}

# Load Balancer for Web Tier
resource "aws_lb" "web_lb" {
  name               = "web-tier-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.web_subnet_1.id, aws_subnet.web_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "Web-Tier-LB"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tier-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.three_tier_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

resource "aws_lb_listener" "web_lb_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Auto Scaling Group for Web Tier
resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-tier-lt"
  image_id      = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = var.web_instance_type
  key_name      = "your-key-pair-name"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Web Tier Instance $(hostname)</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web-Tier-Instance"
      Tier = "Web"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name_prefix          = "web-tier-asg-"
  vpc_zone_identifier  = [aws_subnet.web_subnet_1.id, aws_subnet.web_subnet_2.id]
  desired_capacity     = 2
  min_size             = 2
  max_size             = 4
  health_check_type    = "ELB"

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "Web-Tier-ASG"
    propagate_at_launch = true
  }
}

# App Tier Auto Scaling Group
resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-tier-lt"
  image_id      = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = var.app_instance_type
  key_name      = "your-key-pair-name"

  network_interfaces {
    security_groups = [aws_security_group.app_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Install application dependencies here
              echo "Application Tier Instance $(hostname)" > /tmp/app-ready
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "App-Tier-Instance"
      Tier = "Application"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name_prefix          = "app-tier-asg-"
  vpc_zone_identifier  = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id]
  desired_capacity     = 2
  min_size             = 2
  max_size             = 4

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "App-Tier-ASG"
    propagate_at_launch = true
  }
}

# Database Tier (RDS)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]

  tags = {
    Name = "DB-Subnet-Group"
  }
}

resource "aws_db_instance" "database" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.db_instance_class
  db_name                = "threeTierDB"
  username               = "admin"
  password               = var.db_password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az               = false # Set to true for production
  backup_retention_period = 7
  apply_immediately      = true

  tags = {
    Name = "Three-Tier-DB"
  }
}

# Outputs
output "web_lb_dns" {
  description = "DNS name of the web load balancer"
  value       = aws_lb.web_lb.dns_name
}

output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.database.endpoint
  sensitive   = true
}