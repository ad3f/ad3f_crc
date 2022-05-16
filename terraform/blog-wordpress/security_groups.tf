#Create securtiy groups to be referenced

#Alb security group
resource "aws_security_group" "sg-alb" {
  provider = aws.aws-main
  name     = "crc-sg-alb"
  vpc_id   = aws_vpc.vpc_main.id

  ingress {
    description = "Allow 80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
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
    "Name"       = "aws-sg-alb-wp-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#security group for EC2 Web Application frontend (wordpress instance)

resource "aws_security_group" "sg-ec2-wp" {
  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-alb.id]
  }

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-alb.id]
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.vpc_main.id
  tags = {
    "Name"       = "aws-sg-ec2-wp-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#security group for RDS MYSQL instance
#only allow ingress access from any instance with our sg "sg-ec2-wp" attached

resource "aws_security_group" "sg-rds-wp" {
  ingress {
    description     = "MYSQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-ec2-wp.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.vpc_main.id
  tags = {
    "Name"       = "aws-sg-rds-wp-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

