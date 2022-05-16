# Create our Application Load Balancer which will reside in our main vpc region. 
#Create alb resource type aws_lb
# set our provider to main region provider
# set our name
# set type to application
# internal = false as this will be exposed to the public internet traffic
# attach our security groups
# define subnets this ALB can communicate with
# set our tags

resource "aws_lb" "crc-wp-alb" {
  provider           = aws.aws-main
  name               = "crc-wp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-alb.id]
  subnets            = [aws_subnet.pub-sub.id, aws_subnet.pub-sub2.id]
  tags = {
    "Name"       = "aws-alb-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

# Application Load Balancer requires a target group to be attached to it, so that it can route traffic to 
# whatever entity is attached to the target group
# define resource type as aws_lb_target_group
# need to define a health check block that will be used by the ALB to perform health checks on the target group intances
#### enabled = true as we want to use this to perform health checks as well as instance status checks
#### interval = 10 : how many seconds between health checks
#### path : destination to ping in order to see if instance is healthy " / " default path for webserver
#### port : var.webserver-port port to communicate with instance on
#### protocol : "HTTP" protocol to check over
#### matcher : "200-299" match the response code with webserver for a successful health check if response code is betwen
#### 200 and 299

resource "aws_lb_target_group" "alb-tg" {
  provider    = aws.aws-main
  name        = "crc-alb-tg"
  port        = "80"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_main.id
  protocol    = "HTTP"
  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = "80"
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    "Name"       = "aws-alb-tg-tf",
    "Use"        = "cloud-resume-challenge",
    "Deployment" = "tf"
  }
}

#We need to create the listener for the Application Load Balancer that defines what traffic it is looking for
# and what to do with that traffic
#Create the listener
# Set the load balancer arn to the load balancer we created above
# port to port 80 for http traffic
# protocol to be HTTP
# default_action => what to do with the traffic { type = forward, target_group_arn = <defined_tg>}
resource "aws_lb_listener" "alb-listener-http" {
  provider          = aws.aws-main
  load_balancer_arn = aws_lb.crc-wp-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}

# Define a target group attachment that will be associating our target group with our jenkins master node
# define our target group
# define the instance to associate with the TG
# define the port to communicate over
resource "aws_lb_target_group_attachment" "alb-tg-attach" {
  provider         = aws.aws-main
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.ec2-wp.id
  port             = "80"
}

#Create Route 53 record for ALB
resource "aws_route53_record" "dns-alb-wp" {
  zone_id = var.route53-ad3f-zone-id
  name    = "blog.ad3f.me"
  type    = "A"

  alias {
    name                   = aws_lb.crc-wp-alb.dns_name
    zone_id                = aws_lb.crc-wp-alb.zone_id
    evaluate_target_health = true
  }
}