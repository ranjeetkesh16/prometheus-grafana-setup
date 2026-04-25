terraform {
  backend "s3" {
    bucket         = "pathnex-devops-terraform"  # Change according to your S3 
    key            = "batch/april/monitoring/terraform.tfstate"  # Change according to your path 
    region         = "ap-south-1"
    dynamodb_table = "april2026-monitoring-locks" # optional but recommended, change according to your table name
    encrypt        = true
  }
}