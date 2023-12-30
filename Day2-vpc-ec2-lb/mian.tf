resource "aws_vpc" "rabia_vpc" {
    
    cidr_block = var.cidr
}

resource "aws_subnet" "sub1"{
    
    vpc_id = aws_vpc.rabia_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2"{
    
    vpc_id = aws_vpc.rabia_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw"{
    
    vpc_id = aws_vpc.rabia_vpc.id
    
}

resource "aws_route_table" "rabia_RT" {
    
     vpc_id = aws_vpc.rabia_vpc.id
     route {
         
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
     }
}

resource "aws_route_table_association" "rabia_RT_association1" {
    
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.rabia_RT.id
}

resource "aws_route_table_association" "rabia_RT_association2" {
    
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.rabia_RT.id
}

# Security Group for webserver 
resource "aws_security_group" "web_sg" {
  name        = "websg"
 // description = "Allow HTTP and SSH inbound traffic from internet"
  vpc_id      =  aws_vpc.rabia_vpc.id
  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    //security_groups = [aws_security_group.bastion_sg.id]
       cidr_blocks      = ["0.0.0.0/0"]
  }
  

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
   // security_groups = [aws_security_group.bastion_sg.id]
      cidr_blocks      = ["0.0.0.0/0"]
  }
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  
  tags = {
      Name = "web_sg_rabia_tag"
  }
  
}

resource "aws_s3_bucket" "rabia_s3_bucket" {

 bucket= "rkhalid880bucket"
 
    
}

# ami-079db87dc4c10ac91

resource "aws_instance" "webserver1" {
  ami                    = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"    
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id = aws_subnet.sub1.id
  user_data  = base64encode(file("userdata.sh"))
}

resource "aws_instance" "webserver2" {
  ami                    = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"
   vpc_security_group_ids = [aws_security_group.web_sg.id]
 
  subnet_id = aws_subnet.sub2.id
  user_data = base64encode(file("userdata1.sh"))
}

# creating load balancer
resource "aws_lb" "rabia_alb" {
    
    name = "myalb"
    internal = false
    load_balancer_type = "application"
    security_groups =  [aws_security_group.web_sg.id]
    subnets = [aws_subnet.sub1.id, aws_subnet.sub2.id]
    
}
# creating target group load balancer will distribbute traffic to this target group
# The purpose of the target group is to define a set of instances that can receive traffic from the ALB. 
# The health check settings ensure that only healthy instances receive traffic.
# This target group will be used in conjunction with the ALB listener to route incoming requests to the instances 
# in a balanced manner based on health and load balancing algorithm settings

resource "aws_lb_target_group" "rabia_tg" {
    
    name = "mytg"
    port = 80
    protocol = "HTTP"
    vpc_id  =  aws_vpc.rabia_vpc.id
    
    health_check {
    
    path = "/"
    port = "traffic-port"
    
    }
}

#creating an attachment between an instance (webserver1) and a target group (rabia_tg) associated with an AWS Application Load Balancer (ALB)

resource "aws_lb_target_group_attachment" "rabia_lb_attachment1" {
    
    target_group_arn = aws_lb_target_group.rabia_tg.arn
    target_id = aws_instance.webserver1.id
    port = 80
}

#creating an attachment between an instance (webserver2) and a target group (rabia_tg) associated with an AWS Application Load Balancer (ALB)
resource "aws_lb_target_group_attachment" "rabia_lb_attachment2" {
    
    target_group_arn = aws_lb_target_group.rabia_tg.arn
    target_id = aws_instance.webserver2.id
    port = 80
}

# aws_lb_listener determines where the traffic should be directed (to which target group) and how the ALB should handle the requests.
# Without this listener configuration, the ALB would not know where to route incoming requests, and they would not reach 
# the intended backend instances.

resource "aws_lb_listener" "rabia_listener" {
    
    load_balancer_arn = aws_lb.rabia_alb.arn
    port = 80
    protocol = "HTTP"
    
    default_action {
        
        target_group_arn = aws_lb_target_group.rabia_tg.arn
        type = "forward"
    }
}

output "loadbalancer" {
    
    value = aws_lb.rabia_alb.dns_name
}