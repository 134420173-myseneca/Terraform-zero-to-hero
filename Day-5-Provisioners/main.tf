# Define the AWS 
provider "aws" {
  #  profile = "default"
  region = "us-east-1"
}

variable "vpc-cider" {

  default = "10.0.0.0/16"
}

resource "aws_key_pair" "example" {

  key_name   = "rabia-demo"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_vpc" "rabia_vpc" {

  cidr_block = var.vpc-cider
}

resource "aws_subnet" "sub1" {

  vpc_id                  = aws_vpc.rabia_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}



resource "aws_internet_gateway" "igw" {

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

  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rabia_RT.id
}


# Security Group for webserver 
resource "aws_security_group" "web_sg" {
  name = "websg"
  // description = "Allow HTTP and SSH inbound traffic from internet"
  vpc_id = aws_vpc.rabia_vpc.id
  ingress {
    description = "HTTP from everywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    //security_groups = [aws_security_group.bastion_sg.id]
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "SSH from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    // security_groups = [aws_security_group.bastion_sg.id]
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "web_sg_rabia_tag"
  }

}

resource "aws_instance" "webserver1" {
  ami           = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.example.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.sub1.id

  connection {

    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip

  }

  provisioner "file" {

    source      = "app.py"
    destination = "/home/ec2-user/app.py"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo yum update -y",          # Update system packages
      "sudo yum install -y python3-pip", # Install Python 3
      "sudo pip3 install flask",     # Install Flask
      "cd /home/ec2-user",
    
      "nohup sudo python3 app.py > /dev/null 2>&1 &",
    ]
  }

}