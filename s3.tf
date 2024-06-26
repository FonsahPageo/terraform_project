resource "aws_kms_key" "fonsah_kms_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "fonsah_backend" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "fonsah_bucket_encryption" {
  bucket = aws_s3_bucket.fonsah_backend.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.fonsah_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "fonsah_versioning" {
  bucket = aws_s3_bucket.fonsah_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}