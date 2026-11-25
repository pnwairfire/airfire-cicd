variable "aws_region" {
  description = "AWS region for the CodeBuild GitHub Actions runner."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI profile for local runs. Set to empty string in OIDC/CI environments."
  type        = string
  default     = "uw"
}

variable "github_org" {
  description = "GitHub organization name authorized for the org-level CodeBuild runner webhook."
  type        = string
  default     = "pnwairfire"
}

variable "project_name" {
  description = "AWS CodeBuild project name (referenced in GitHub Actions runs-on labels)."
  type        = string
  default     = "pnwairfire-gh-runner"
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
