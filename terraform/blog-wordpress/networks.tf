#create VPC in Sydney Region - ap-southeast-2
#passthrough resource type " aws_vpc "
#VPC configurations:
#provider alias
#cidr_block
#iff dns resolver and hostname auto support
#tags

#------------------------------------------------------
#Fetch data

#retrieve AZs in Sydney region ( location of main vpc )
#store available AZs in list ref azs-syd
data "aws_availability_zones" "azs-syd" {
  provider = aws.aws-main
  state    = "available"
}

#------------------------------------------------------
#Resources 

#create VPC
resource "aws_vpc" "vpc_main" {
  provider             = aws.aws-main
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name"       = "main-vpc-tf",
    "Use"        = "cloud-resume-challenge-tf",
    "Deployment" = "tf"
  }
}

#Create IGW for VPC
#attache main vpc
resource "aws_internet_gateway" "igw-syd-main" {
  provider = aws.aws-main
  vpc_id   = aws_vpc.vpc_main.id
  tags = {
    "Name"       = "aws-igw-syd-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#Create subnets.
#Public subnet for Application Instance
#element(~) = will return AZ at index 0 of our list
#map_public_ip auto assign public ipv4 address to instances launched in subnet on creation
resource "aws_subnet" "pub-sub" {
  provider                = aws.aws-main
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = element(data.aws_availability_zones.azs-syd.names, 0)
  map_public_ip_on_launch = true
  tags = {
    "Name"       = "aws-pub-sub-syd-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#Public subnet for Application Instance (second required only for integration wtih ALB PRACTICE)
#element(~) = will return AZ at index 0 of our list
#map_public_ip auto assign public ipv4 address to instances launched in subnet on creation
resource "aws_subnet" "pub-sub2" {
  provider                = aws.aws-main
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = element(data.aws_availability_zones.azs-syd.names, 1)
  map_public_ip_on_launch = true
  tags = {
    "Name"       = "aws-pub-sub2-syd-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#Private Subnet for our RDS instance
#select AZ at index 1 to have in seperate AZ
resource "aws_subnet" "pvt-sub" {
  provider                = aws.aws-main
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = element(data.aws_availability_zones.azs-syd.names, 1)
  map_public_ip_on_launch = false
  tags = {
    "Name"       = "aws-pvt-sub-syd-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#Private Subnet for our RDS instance
#select AZ at index 1 to have in seperate AZ
resource "aws_subnet" "pvt-sub2" {
  provider                = aws.aws-main
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = element(data.aws_availability_zones.azs-syd.names, 0)
  map_public_ip_on_launch = false
  tags = {
    "Name"       = "aws-pvt-sub2-syd-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#Create elastic IP for NAT gateway
resource "aws_eip" "eip-nat" {
  vpc = true
  depends_on = [
    aws_internet_gateway.igw-syd-main
  ]
  tags = {
    "Name"       = "aws-eip-ngw",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#Create NAT gateway for pvt sub to comm externally
resource "aws_nat_gateway" "ngw-syd-main-pub" {
  allocation_id = aws_eip.eip-nat.id
  subnet_id     = aws_subnet.pub-sub.id
  depends_on = [
    aws_internet_gateway.igw-syd-main
  ]
  tags = {
    "Name"       = "aws-ngw-syd-pub-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#Create Route tables
#Route table for pub sub
resource "aws_route_table" "rt-pub" {
  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-syd-main.id
  }
  tags = {
    "Name"       = "aws-rt-pub-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#route table for pvt subnet
resource "aws_route_table" "rt-pvt" {
  vpc_id = aws_vpc.vpc_main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw-syd-main-pub.id
  }
  tags = {
    "Name"       = "aws-rt-pvt-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#associate route table for pub subnet to created sub
resource "aws_route_table_association" "rt-pub-assoc" {
  subnet_id      = aws_subnet.pub-sub.id
  route_table_id = aws_route_table.rt-pub.id
}

#associate route table for pub subnet to created sub
resource "aws_route_table_association" "rt-pub2-assoc" {
  subnet_id      = aws_subnet.pub-sub2.id
  route_table_id = aws_route_table.rt-pub.id
}

#associate pvt route table with pvt sub
resource "aws_route_table_association" "rt-pvt-assoc" {
  subnet_id      = aws_subnet.pvt-sub.id
  route_table_id = aws_route_table.rt-pvt.id
}

#associate pvt route table with pvt sub 2
resource "aws_route_table_association" "rt-pvt2-assoc" {
  subnet_id      = aws_subnet.pvt-sub2.id
  route_table_id = aws_route_table.rt-pvt.id
}