moved {
  from = aws_codeconnections_connection.github
  to   = module.runner.aws_codeconnections_connection.github
}

module "runner" {
  source = "../modules/codebuild_runner"

  github_org      = var.github_org
  connection_name = "pnwairfire-github"
  project_name    = var.project_name
}
