terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "default"
}

resource "aws_default_vpc" "default_vpc" {

  tags = {
    Name = "default vpc"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}


# create default subnet if one does not exit
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}


# create security group for the ec2 instance
resource "aws_security_group" "jfrog-ec2_security_group" {
  name        = "artifactory ec2 security group"
  description = "allow access on ports 8081, 8082 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  # allow access on port 9000
  ingress {
    description = "http proxy access"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http proxy access"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow access on port 22
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "artifactory server security group"
  }
}

# launch the ec2 instance and install website
resource "aws_instance" "jfrog-ec2_instance" {
  ami                    = "ami-0c9f6749650d5c0e3"
  instance_type          = "t2.medium"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.jfrog-ec2_security_group.id]
  key_name               = "jenkins-ec2"

  root_block_device {
    volume_size = 16
  }

  tags = {
    Name = "Jfrog-artifactory"
  }
}

# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("C:/Users/padda/Downloads/jenkins-ec2.pem")
    host        = aws_instance.jfrog-ec2_instance.public_ip
  }

  provisioner "file" {
    source      = "C:/Users/padda/OneDrive/Desktop/Cloud_Computing/DevOps_Projects/Artifactory-installation/terraform_code/install_artifactory.sh"
    destination = "/tmp/install_artifactory.sh"
  }

  # set permissions and run the install_jenkins.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_artifactory.sh",
      "sh /tmp/install_artifactory.sh"
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.jfrog-ec2_instance]
}


# print the url of the jenkins server
output "website_url" {
  value = join("", ["http://", aws_instance.jfrog-ec2_instance.public_dns, ":", "8081"])
}
