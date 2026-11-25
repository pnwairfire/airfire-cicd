output "codeconnection_arn" {
  description = "ARN of the UW AWS CodeConnections GitHub connection."
  value       = module.runner.codeconnection_arn
}

output "codeconnection_status" {
  description = "Current status of the UW AWS CodeConnections GitHub connection."
  value       = module.runner.codeconnection_status
}

output "codeconnection_console_url" {
  description = "AWS Console URL to authorize the pending UW GitHub connection."
  value       = module.runner.codeconnection_console_url
}

output "codebuild_project_name" {
  description = "Name of the UW AWS CodeBuild project."
  value       = module.runner.codebuild_project_name
}

output "runs_on_expression" {
  description = "GitHub Actions runs-on expression targeting the UW CodeBuild runner."
  value       = module.runner.runs_on_expression
}
