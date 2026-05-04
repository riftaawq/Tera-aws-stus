provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "user1" {
  name = "az104-user1"
  tags = {
    JobTitle   = "IT Lab Administrator"
    Department = "IT"
    Location   = "United States"
  }
}

resource "aws_iam_user" "guest" {
  name = "guest-user"
  tags = {
    JobTitle   = "IT Lab Administrator"
    Department = "IT"
    Location   = "United States"
  }
}

resource "aws_iam_group" "it_admins" {
  name = "IT-Lab-Administrators"
}

resource "aws_iam_group_membership" "team" {
  name = "it-lab-membership"
  users = [
    aws_iam_user.user1.name,
    aws_iam_user.guest.name,
  ]
  group = aws_iam_group.it_admins.name
}

resource "aws_iam_group" "helpdesk" {
  name = "helpdesk"
}

resource "aws_iam_group_membership" "helpdesk_members" {
  name = "helpdesk-membership"
  users = [
    aws_iam_user.user1.name
  ]
  group = aws_iam_group.helpdesk.name
}

resource "aws_iam_policy" "custom_support" {
  name        = "CustomSupportRequest"
  description = "Allows EC2 and Support management, denies provider registration"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
          "support:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "support:RegisterSupportProvider"
        ]
        Effect   = "Deny"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "attach_custom_policy" {
  group      = aws_iam_group.helpdesk.name
  policy_arn = aws_iam_policy.custom_support.arn
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_ebs_volume" "lab_disk" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.disk_size
  type              = "gp2"

  tags = {
    Name = var.disk_name
  }
}