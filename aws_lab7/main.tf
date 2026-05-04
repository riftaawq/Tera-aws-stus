provider "aws" {
  region = "us-east-2"
}

# -------------------------
# RANDOM ID
# -------------------------
resource "random_id" "id" {
  byte_length = 4
}

# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.70.0.0/16"
}

# Route table (required for endpoint)
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
}

# -------------------------
# S3 BUCKET
# -------------------------
resource "aws_s3_bucket" "lab_bucket" {
  bucket              = "aws-lab7-storage-${random_id.id.hex}"
  object_lock_enabled = true
  force_destroy       = true
}

# FIX ДЛЯ S3 REGION (ГОЛОВНЕ!)
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.lab_bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# -------------------------
# VERSIONING (ОБОВʼЯЗКОВО)
# -------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.lab_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------------
# LIFECYCLE
# -------------------------
resource "aws_s3_bucket_lifecycle_configuration" "lab_lifecycle" {
  bucket = aws_s3_bucket.lab_bucket.id

  rule {
    id     = "MoveToIA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# -------------------------
# OBJECT LOCK (WORM)
# -------------------------
resource "aws_s3_bucket_object_lock_configuration" "lab_lock" {
  bucket = aws_s3_bucket.lab_bucket.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 180
    }
  }

  depends_on = [aws_s3_bucket_versioning.versioning]
}

# -------------------------
# S3 VPC ENDPOINT
# -------------------------
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.rt.id]
}

# -------------------------
# BUCKET POLICY (VPC ONLY)
# -------------------------
resource "aws_s3_bucket_policy" "restrict_to_vpc" {
  bucket = aws_s3_bucket.lab_bucket.id

  depends_on = [aws_vpc_endpoint.s3_endpoint]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyOutsideVPC"
        Effect    = "Deny"
        Principal = "*"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = [
          "${aws_s3_bucket.lab_bucket.arn}/*"
        ]

        Condition = {
          StringNotEquals = {
            "aws:SourceVpce" = aws_vpc_endpoint.s3_endpoint.id
          }
        }
      }
    ]
  })
}

# -------------------------
# OUTPUT
# -------------------------
output "bucket_name" {
  value = aws_s3_bucket.lab_bucket.bucket
}