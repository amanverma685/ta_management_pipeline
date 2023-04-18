resource "aws_vpc" "main" {
cidr_block = "10.0.0.0/16"
enable_dns_hostnames = true
enable_dns_support   = true
}

resource "aws_subnet" "private-subnet1" {
vpc_id = aws_vpc.main.id
cidr_block = "10.0.2.0/24"
availability_zone = "us-east-2a"
}

resource "aws_subnet" "private-subnet2" {
vpc_id = aws_vpc.main.id
cidr_block = "10.0.3.0/24"
availability_zone = "us-east-2b"
}

resource "aws_db_subnet_group" "db_subnet" {
name = "vt_subnet_group"
subnet_ids = ["${aws_subnet.private-subnet1.id}", "${aws_subnet.private-subnet2.id}"]
}

resource "aws_security_group" "rds" {

  name_prefix = "rds-"
  vpc_id      = aws_vpc.main.id
   // Inbound rules
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Outbound rules
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}



resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.example.id
}


resource "aws_db_instance" "postgresql" {
  identifier             = "surveymanagement"
  engine                 = "postgres"
  engine_version         = "13.7"
  instance_class         = "db.t3.micro"
  db_name                = "vt_survey_management"
  username               = "postgres"
  allocated_storage      = 5
  password               = "admin123"
  skip_final_snapshot    = true 
  publicly_accessible    = true
  storage_encrypted      = false
  db_subnet_group_name = "${aws_db_subnet_group.db_subnet.name}"
  vpc_security_group_ids = [aws_security_group.rds.id]
  tags = {
    Name = "surveymanagement"
  }

}

