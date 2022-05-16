#data fetch required information for our instances

#------------------------------------------------------
#Fetch data

#Latest AMI information for Sydney region
data "aws_ssm_parameter" "aws-linux-ami" {
  provider = aws.aws-main
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Data for use with wordpress instance and db: username and pass
data "aws_ssm_parameter" "db-username" {
  provider = aws.aws-main
  name     = "crc-wp-db-user"
}

data "aws_ssm_parameter" "db-pass" {
  provider = aws.aws-main
  name     = "crc-wp-db-password"
}

data "aws_ssm_parameter" "wp-user" {
  provider = aws.aws-main
  name     = "crc-wp-user"
}

data "aws_ssm_parameter" "wp-pass" {
  provider = aws.aws-main
  name     = "crc-wp-password"
}


#------------------------------------------------------
#Resources

# Using the command ssh-keygen -t rsa we create a private and public key locally
# Create key pair resource for logging into our main region ec2 instances
# create resource type aws_key_pair
# provider is set to our main vpc region
# key_name name for our key on aws
# public_key is the public key file that we created as output from our terminal command as per above. 
resource "aws_key_pair" "key-crc" {
  provider   = aws.aws-main
  key_name   = "crc-ad"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Create our database subnet group
resource "aws_db_subnet_group" "rds-subnet-group" {
  depends_on = [
    aws_subnet.pvt-sub
  ]
  provider   = aws.aws-main
  name       = "crc-wp-db-group"
  subnet_ids = [aws_subnet.pvt-sub.id, aws_subnet.pvt-sub2.id]
}

#create rds mysql instance in pvt subnet
resource "aws_db_instance" "rds-mysql-wp" {
  provider               = aws.aws-main
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = var.rds-db-instance
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.id
  vpc_security_group_ids = [aws_security_group.sg-rds-wp.id]
  db_name                = var.database_name
  username               = data.aws_ssm_parameter.db-username.value
  password               = data.aws_ssm_parameter.db-pass.value
  skip_final_snapshot    = true
  multi_az               = false
}

#Create our wordpress EC2 instance
resource "aws_instance" "ec2-wp" {
  provider = aws.aws-main
  depends_on = [
    aws_subnet.pub-sub,
    aws_key_pair.key-crc,
    aws_security_group.sg-ec2-wp,
    aws_db_instance.rds-mysql-wp
  ]
  ami             = data.aws_ssm_parameter.aws-linux-ami.value
  instance_type   = var.default-instance
  subnet_id       = aws_subnet.pub-sub.id
  security_groups = [aws_security_group.sg-ec2-wp.id]
  user_data = templatefile("./user_data.tpl",
    {
      db_username      = data.aws_ssm_parameter.db-username.value
      db_user_password = data.aws_ssm_parameter.db-pass.value
      db_name          = var.database_name
      db_RDS           = aws_db_instance.rds-mysql-wp.endpoint
    }
  )
  key_name = aws_key_pair.key-crc.id
}


### 
