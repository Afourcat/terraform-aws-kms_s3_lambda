variable "enable_cloudwatch" {
  type        = bool
  description = "Enable the lambda to log on cloudwatch. default to false."
  default     = false
}

variable "prefix" {
  type        = string
  description = "A prefix most of the time, the region or environment of the project."
}

variable "name" {
  type        = string
  description = "The name of the lambda and the prefix of the s3-bucket."
}

variable "layers" {
  type        = list(string)
  description = "The layers id for the lambda.value"
  default     = []
}

variable "policy" {
  type        = string
  description = "An Iam policy allowing some AWS access to the lambda."
  default     = null
}

variable "runtime" {
  type        = string
  description = "The runtime environement of the lambda. By default, latest nodejs runtime."
  default     = "nodejs16.x"
}

variable "handler" {
  type        = string
  description = "The handler name of the lambda. By default, index.handler."
  default     = "index.handler"
}

variable "memory" {
  type        = string
  description = "The memory of the lambda in mb."
  default     = 128
}

variable "kms_key_id" {
  type = string
  description = "The KMS key if you want to provide one, otherwise, created by the module"
  default = null
}
