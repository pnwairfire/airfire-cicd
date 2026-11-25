data "aws_region" "current" {}

resource "aws_codeconnections_connection" "github" {
  name          = var.connection_name
  provider_type = "GitHub"
}

resource "aws_cloudwatch_log_group" "codebuild_runner" {
  name              = "/aws/codebuild/${var.project_name}"
  retention_in_days = var.log_retention_days
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_runner" {
  name               = "${var.project_name}-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_runner" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.codebuild_runner.arn,
      "${aws_cloudwatch_log_group.codebuild_runner.arn}:*",
    ]
  }

  statement {
    sid    = "CodeConnectionsAccess"
    effect = "Allow"
    actions = [
      "codeconnections:GetConnection",
      "codeconnections:GetConnectionToken",
      "codeconnections:UseConnection",
      "codestar-connections:GetConnection",
      "codestar-connections:UseConnection",
    ]
    resources = [
      aws_codeconnections_connection.github.arn,
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_runner" {
  name   = "${var.project_name}-policy"
  role   = aws_iam_role.codebuild_runner.id
  policy = data.aws_iam_policy_document.codebuild_runner.json
}

resource "aws_codebuild_project" "github_runner" {
  name          = var.project_name
  description   = "Ephemeral AWS CodeBuild self-hosted GitHub Actions runner for ${var.github_org}"
  service_role  = aws_iam_role.codebuild_runner.arn
  build_timeout = var.build_timeout_minutes

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_runner.name
      status     = "ENABLED"
    }
  }

  source {
    type            = "GITHUB"
    location        = "CODEBUILD_DEFAULT_WEBHOOK_SOURCE_LOCATION"
    git_clone_depth = 1

    auth {
      type     = "CODECONNECTIONS"
      resource = aws_codeconnections_connection.github.arn
    }
  }

  depends_on = [aws_iam_role_policy.codebuild_runner]
}

resource "aws_codebuild_webhook" "github_runner" {
  project_name = aws_codebuild_project.github_runner.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }

  scope_configuration {
    scope = "GITHUB_ORGANIZATION"
    name  = var.github_org
  }
}
