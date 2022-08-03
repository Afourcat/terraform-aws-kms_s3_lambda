provider "aws" {}

locals {
  need_kms                = var.kms_key_id == null
  name                    = "${var.prefix != "" ? "${var.prefix}-" : ""}${var.name}"
  default_base64_function = <<-EOF
    UEsDBBQAAAAIAAplA1VV/4tRsAAAAP4AAAAIABwAaW5kZXguanNVVAkAA5RQ6mKbU
    OpidXgLAAEE9QEAAAQUAAAAPY7LCsIwEEX3/YoxK4X6QMSF4MYi+AGCS4nNFAthJm
    QmYJH+uwkt7oYz514ufgJHlc3bkvMY4QxWBmqhS9Rqz7R81vBcwbcCaJlEgZOGpNk
    zN/Sea3hw9G5hqr8RUUI+MDslBmBErSZp2KE5wX63qyf8RuswSmaTl1HDpEi6vg+h
    uEbxo9vgbU9mCo1ztpeLFTwertTmWpfdznrB+ftiN2Q0bS1sLPMiaor031eN1Q9QS
    wECHgMUAAAACAAKZQNVVf+LUbAAAAD+AAAACAAYAAAAAAABAAAApIEAAAAAaW5kZX
    guanNVVAUAA5RQ6mJ1eAsAAQT1AQAABBQAAABQSwUGAAAAAAEAAQBOAAAA8gAAAAA
    A
  EOF
}

# == Bucket == #

resource "aws_s3_bucket" "this" {
  bucket = "lambda-${local.name}-code"

  tags = {
    Type = "Code"
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.bucket
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_key.this.key_id
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# == KMS == #

data "aws_kms_key" "this" {
  key_id = local.need_kms ? aws_kms_key.this[0].id : var.kms_key_id
}

resource "aws_kms_key" "this" {
  count                   = local.need_kms ? 1 : 0
  description             = "The kms key for the ${aws_s3_bucket.this.bucket}."
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "ingest" {
  count         = local.need_kms ? 1 : 0
  name          = "alias/${aws_s3_bucket.this.bucket}"
  target_key_id = aws_kms_key.this[0].id
}

# == Lambda == #

resource "aws_iam_role" "iam_for_lambda" {
  name_prefix        = "lambda-${local.name}"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_s3_object" "initial" {
  bucket                 = aws_s3_bucket.this.bucket
  key                    = "source"
  server_side_encryption = "aws:kms"
  content_base64         = local.default_base64_function
}

resource "aws_iam_role_policy" "user_given_policy" {
  count = var.policy == null ? 0 : 1

  role   = aws_iam_role.iam_for_lambda.id
  policy = var.policy
}

resource "aws_lambda_function" "this" {
  function_name = local.name
  runtime       = var.runtime
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = var.handler
  s3_bucket     = aws_s3_bucket.this.bucket
  s3_key        = "source"

  memory_size = var.memory
  layers      = var.layers

  depends_on = [
    aws_s3_object.initial
  ]
}

# == CloudWatch == #

resource "aws_iam_role_policy" "logging" {
  count = var.enable_cloudwatch ? 1 : 0
  role  = aws_iam_role.iam_for_lambda.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  }
  EOF
}
