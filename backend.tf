# terraform {
#   backend "s3" {
#     bucket = "fonsah-logs-and-backend"
#     key = "terraform/tf-state/terraform.tf-state"
#     region = "us-east-2"
#     encrypt = true
#     dynamodb_table = "fonsah-dynamodb-table"
#   }
# }