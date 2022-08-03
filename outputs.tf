output "s3_bucket" {
  value = aws_s3_bucket.this.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

output "s3_object_name" {
  value = "source"
}

output "kms_key_id" {
  value = data.aws_kms_key.this.key_id
}
