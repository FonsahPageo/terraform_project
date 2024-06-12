resource "aws_dynamodb_table" "fonsah_dynamodb_table" {
  name = var.dynamodb_name
  billing_mode = var.billing_mode
  hash_key = var.hash_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  tags = {
    Name = var.dynamodb_name
  }
}