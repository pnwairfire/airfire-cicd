variable "aws_region" {
  description = "AWS region for the EPA CodeBuild GitHub Actions runner."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI profile for local runs. Set to empty string in OIDC/CI environments."
  type        = string
  default     = "epa"
}

variable "github_org" {
  description = "GitHub organization name authorized for the org-level CodeBuild runner webhook."
  type        = string
  default     = "pnwairfire"
}

variable "project_name" {
  description = "AWS CodeBuild project name for EPA-account repositories."
  type        = string
  default     = "pnwairfire-epa-gh-runner"
}
