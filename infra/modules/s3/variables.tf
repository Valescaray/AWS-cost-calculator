variable "bucket_name" {
  description = "Name of the S3 bucket for cost reports and dashboard hosting"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = true
}

variable "dashboard_source_dir" {
  type        = string
  description = "Path to dashboard files (HTML, CSS, JS) to upload to S3"
  default     = "../dashboard"
}

variable "upload_dashboard" {
  type        = bool
  description = "Whether to upload dashboard files to S3"
  default     = true
}
