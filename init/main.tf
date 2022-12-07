locals {
  tags = {
    Environment = Dev
  }
}

resource "aws_kms_key" "key" {
  description              = "KMS Key"
  key_usage                = "ENCRYPT_DECRYPT"
  deletion_window_in_days  = 30
  enable_key_rotation      = True
  customer_master_key_spec = "SYMMETRIC_DEFAULT"

  tags = local.tags
}

resource "aws_kms_alias" "key.alias" {
  count         = var.create_alias ? 1 : 0
  name          = "alias/key"
  target_key_id = aws_kms_key.key.id
  tags = local.tags
}


resource "aws_s3_bucket" "tfstate" {
  bucket = "terraform-up-and-running-state"
 
  lifecycle {
    prevent_destroy = true
  }
  tags = local.tags
}


resource "aws_s3_bucket_versioning" "tf-state-file" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}




resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate-enc" {
  bucket = aws_s3_bucket.tfstate

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf-state" {
  name         = "tf-state"
  billing_mode = "PROVISIONED"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}