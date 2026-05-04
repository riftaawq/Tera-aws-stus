# Налаштування провайдера AWS
provider "aws" {
  region = "us-east-1"
}

# 1. Створення внутрішнього користувача (Завдання 1)
resource "aws_iam_user" "user1" {
  name = "az104-user1"
  tags = {
    JobTitle   = "IT Lab Administrator"
    Department = "IT"
    Location   = "United States"
  }
}

# 2. Створення другого користувача (аналог гостя в Azure)
resource "aws_iam_user" "guest" {
  name = "guest-user"
  tags = {
    JobTitle   = "IT Lab Administrator"
    Department = "IT"
    Location   = "United States"
  }
}

# 3. Створення групи (Завдання 2)
resource "aws_iam_group" "it_admins" {
  name = "IT-Lab-Administrators"
}

# 4. Додавання обох користувачів до групи
resource "aws_iam_group_membership" "team" {
  name = "it-lab-membership"

  users = [
    aws_iam_user.user1.name,
    aws_iam_user.guest.name,
  ]

  group = aws_iam_group.it_admins.name
}