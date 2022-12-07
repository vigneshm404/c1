output "bucket_id" {
  description = "tf statefile backup bucket id"
  value       = aws_s3_bucket.tfstate.id
}

output "bucket_arn" {
  description = "tf statefile backup bucket arn"
  value       = aws_kms_key.key.arn
}

output "db_arn" {
  description = "tf statefile backup bucket arn"
  value       = aws_dynamodb_table.tf-state.arn
}

output "db_id" {
  description = "tf statefile backup bucket arn"
  value       = aws_dynamodb_table.tf-state.id
}