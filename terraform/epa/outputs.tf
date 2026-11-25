output "codeconnection_arn" {
  description = "ARN of the EPA AWS CodeConnections GitHub connection."
  value       = module.runner.codeconnection_arn
}

output "codeconnection_status" {
  description = "Current status of the EPA AWS CodeConnections GitHub connection."
  value       = module.runner.codeconnection_status
}

output "codeconnection_console_url" {
  description = "AWS Console URL to authorize the pending EPA GitHub connection."
  value       = module.runner.codeconnection_console_url
}

output "codebuild_project_name" {
  description = "Name of the EPA AWS CodeBuild project."
  value       = module.runner.codebuild_project_name
}

output "runs_on_expression" {
  description = "GitHub Actions runs-on expression targeting the EPA CodeBuild runner."
  value       = module.runner.runs_on_expression
}
