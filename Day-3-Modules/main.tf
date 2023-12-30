provider "aws" {
    
    region = "aws-east-1"
}

module "ec2_instance" {
    
    source = "./modules/ec2_instance"
   ami_value = "ami-079db87dc4c10ac91"
instance_type_value ="t2.micro"
subnet_id_value = "subnet-0c1e20e08e52873df"

}


