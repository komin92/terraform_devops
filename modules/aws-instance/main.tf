#SECURITY GROUP for instance
resource "aws_security_group" "devops-sg" {
    name   = "devops-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port  = 22
        to_port    = 22
        protocol   = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1" #any protocol
        cidr_blocks     = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name = "${var.env_prefix}-security-group"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners      = ["amazon"]
    filter{ #filtered by name
        name   = "name"
        values = [var.image_name]
    }
    filter{ #filtered by virtualization type
        name   = "virtualization-type"
        values = ["hvm"]
    }
    filter {
        name   = "description"
        values = ["Amazon Linux 2 *"]
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name   = "nginx-server-key"
    public_key = file(var.public_key_location)
}

resource "aws_instance" "devops-server" {

    #takes AMI ID that we got from data query
    ami           = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id               = var.subnet_id
    vpc_security_group_ids = [aws_security_group.devops-sg.id]
    availability_zone       = var.az_zone

    associate_public_ip_address = true
    key_name  = aws_key_pair.ssh-key.key_name

    user_data = <<EOF
#! /bin/bash
sudo yum update -y && sudo yum install docker -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user
newgrp docker
docker run -p 8080:80 nginx
EOF


    tags = {
        Name = "${var.env_prefix}-server"
    }


//     provisioner "file" {
//         source      = "entry-script.sh"
//         destination = "/home/ec2-user/entry-script"
//         connection {
//            type     = "ssh"
//            user     = "ec2-user"
//            private_key = var.private_key_location
//            host        = self.public_ip
//         }
//     }
//
//     provisioner "remote-exec" {
//         script = file("entry-script.sh")
//     }




    provisioner "local-exec" {
        command = "echo ${self.public_ip} > output.txt"
    }
}



