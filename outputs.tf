output "s3_bucket" {
  value = aws_s3_bucket.this.bucket
}

output "lambda_arn" {
  value = aws_lambda_function.this.arn
}

output "s3_object_name" {
  value = "source"
}

output "kms_key_id" {
  value = data.aws_kms_key.this.key_id
}
