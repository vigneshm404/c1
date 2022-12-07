terraform {
  backend "s3" {
    bucket = "tfstate"
    key    = "s3/terraform.tfstate"
    region = "us-east-1"
  }
}


