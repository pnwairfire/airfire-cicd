output "codeconnection_arn" {
  description = "ARN of the AWS CodeConnections GitHub connection."
  value       = aws_codeconnections_connection.github.arn
}

output "codeconnection_status" {
  description = "Current status of the AWS CodeConnections GitHub connection."
  value       = aws_codeconnections_connection.github.connection_status
}

output "codeconnection_console_url" {
  description = "AWS Console URL to authorize the pending GitHub connection."
  value       = "https://${data.aws_region.current.region}.console.aws.amazon.com/codesuite/settings/connections"
}

output "codebuild_project_name" {
  description = "Name of the AWS CodeBuild project hosting GitHub Actions runners."
  value       = aws_codebuild_project.github_runner.name
}

output "runs_on_expression" {
  description = "GitHub Actions runs-on expression targeting this CodeBuild runner."
  value       = "codebuild-${var.project_name}-$${{ github.run_id }}-$${{ github.run_attempt }}"
}
