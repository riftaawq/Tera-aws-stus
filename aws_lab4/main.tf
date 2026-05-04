provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "core_services" {
  cidr_block = "10.20.0.0/16"
  tags = {
    Name = "CoreServicesVpc"
  }
}

resource "aws_subnet" "shared_services" {
  vpc_id     = aws_vpc.core_services.id
  cidr_block = "10.20.10.0/24"
  tags = {
    Name = "SharedServicesSubnet"
  }
}

resource "aws_subnet" "database" {
  vpc_id     = aws_vpc.core_services.id
  cidr_block = "10.20.20.0/24"
  tags = {
    Name = "DatabaseSubnet"
  }
}

resource "aws_vpc" "manufacturing" {
  cidr_block = "10.30.0.0/16"
  tags = {
    Name = "ManufacturingVpc"
  }
}

resource "aws_subnet" "sensor1" {
  vpc_id     = aws_vpc.manufacturing.id
  cidr_block = "10.30.20.0/24"
  tags = {
    Name = "SensorSubnet1"
  }
}

resource "aws_subnet" "sensor2" {
  vpc_id     = aws_vpc.manufacturing.id
  cidr_block = "10.30.21.0/24"
  tags = {
    Name = "SensorSubnet2"
  }
}

resource "aws_security_group" "asg_web" {
  name        = "asg-web"
  vpc_id      = aws_vpc.core_services.id
}

resource "aws_security_group" "my_nsg_secure" {
  name        = "myNSGSecure"
  vpc_id      = aws_vpc.core_services.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_web.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.core_services.cidr_block]
  }
}

resource "aws_route53_zone" "public_zone" {
  name = "contoso.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "www.contoso.com"
  type    = "A"
  ttl     = "300"
  records = ["10.1.1.4"]
}

resource "aws_route53_zone" "private_zone" {
  name = "private.contoso.com"
  vpc {
    vpc_id = aws_vpc.manufacturing.id
  }
}

resource "aws_route53_record" "sensorvm" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "sensorvm.private.contoso.com"
  type    = "A"
  ttl     = "300"
  records = ["10.1.1.4"]
}