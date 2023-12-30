#!/bin/bash
sudo yum -y update
sudo yum -y install httpd
myip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
hostname=$(hostname)
environment="Dev"

echo "<h1>Welcome to $environment environment!</h1><br>
      <h1>Load Balancer Project This is webserver 2 </h1>
      <p>This is VM with hostname: $hostname and IP: $myip.</p>
     
      </font></p><ul><li>Rabia Khalid</li></ul>
      <p>Built by Terraform!</p>
      <p>The image below is loaded from S3 bucket<p>
      <img src='https://group7-webserver-files.s3.amazonaws.com/cat.jpeg' alt='Cat image from S3'>
      ">/var/www/html/index.html
      
sudo systemctl start httpd
sudo systemctl enable httpd
