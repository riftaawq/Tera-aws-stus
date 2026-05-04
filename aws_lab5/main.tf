provider "aws" {
  region = "us-east-1"
}

# --- Завдання 1: Core Services VPC та підмережа ---
resource "aws_vpc" "core" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "CoreServicesVnet" }
}

resource "aws_subnet" "core_subnet" {
  vpc_id     = aws_vpc.core.id
  cidr_block = "10.0.0.0/24"
  tags = { Name = "CoreSubnet" }
}

# --- Завдання 2: Manufacturing VPC та підмережа ---
resource "aws_vpc" "manufacturing" {
  cidr_block = "172.16.0.0/16"
  tags = { Name = "ManufacturingVnet" }
}

resource "aws_subnet" "manufacturing_subnet" {
  vpc_id     = aws_vpc.manufacturing.id
  cidr_block = "172.16.0.0/24"
  tags = { Name = "ManufacturingSubnet" }
}

# --- Завдання 4: VPC Peering (З'єднання мереж) ---
resource "aws_vpc_peering_connection" "core_to_manu" {
  vpc_id      = aws_vpc.core.id
  peer_vpc_id = aws_vpc.manufacturing.id
  auto_accept = true # Автоматично приймаємо запит на з'єднання
  tags = { Name = "CoreServices-to-Manufacturing-Peering" }
}

# Оновлюємо стандартні таблиці маршрутизації, щоб вони знали про піринг
resource "aws_default_route_table" "core_default" {
  default_route_table_id = aws_vpc.core.default_route_table_id
  route {
    cidr_block                = aws_vpc.manufacturing.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.core_to_manu.id
  }
  tags = { Name = "CoreServices-Default-RT" }
}

resource "aws_default_route_table" "manu_default" {
  default_route_table_id = aws_vpc.manufacturing.default_route_table_id
  route {
    cidr_block                = aws_vpc.core.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.core_to_manu.id
  }
  tags = { Name = "Manufacturing-Default-RT" }
}

# --- Завдання 6: Custom Route та Perimeter Subnet ---
resource "aws_subnet" "perimeter" {
  vpc_id     = aws_vpc.core.id
  cidr_block = "10.0.1.0/24"
  tags = { Name = "PerimeterSubnet" }
}

# Імітація Network Virtual Appliance (NVA) через мережевий інтерфейс
resource "aws_network_interface" "nva" {
  subnet_id   = aws_subnet.perimeter.id
  private_ips = ["10.0.1.7"]
  tags = { Name = "NVA-Interface" }
}

# Створення кастомної таблиці маршрутизації
resource "aws_route_table" "rt_core" {
  vpc_id = aws_vpc.core.id
  
  # Весь зовнішній трафік направляємо на наш віртуальний фаєрвол (NVA)
  route {
    cidr_block           = "0.0.0.0/0" 
    network_interface_id = aws_network_interface.nva.id
  }
  tags = { Name = "rt-CoreServices" }
}

# Прив'язка кастомного маршруту до Perimeter Subnet
resource "aws_route_table_association" "perimeter_assoc" {
  subnet_id      = aws_subnet.perimeter.id
  route_table_id = aws_route_table.rt_core.id
}