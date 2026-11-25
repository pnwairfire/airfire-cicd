variable "github_org" {
  description = "GitHub organization name authorized for the org-level CodeBuild runner webhook."
  type        = string
  default     = "pnwairfire"
}

variable "connection_name" {
  description = "Name of the AWS CodeConnections GitHub connection."
  type        = string
}

variable "project_name" {
  description = "AWS CodeBuild project name (referenced in GitHub Actions runs-on labels)."
  type        = string
}

variable "compute_type" {
  description = "Default CodeBuild compute size (can be overridden per workflow via runs-on label)."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "CodeBuild Ubuntu container image supporting Docker, Python, Node.js, and Terraform."
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "build_timeout_minutes" {
  description = "Maximum duration in minutes for a single GitHub Actions job on CodeBuild."
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days for CodeBuild runner logs."
  type        = number
  default     = 14
}
