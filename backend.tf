terraform {
  backend "s3" {
    # Replace with the name of the S3 bucket you created
    bucket = "home-lab-bucker-v1" # <-- IMPORTANT: Use a globally unique name

    key            = "home-lab-k8/terraform.tfstate"
    region         = "us-west-2" # Must match your bucket's region
    dynamodb_table = "home-lab-lock-table" # Replace with your DynamoDB table name
    encrypt        = true
  }
}
