module "runner" {
  source = "../modules/codebuild_runner"

  github_org      = var.github_org
  connection_name = "pnwairfire-epa-github"
  project_name    = var.project_name
}
