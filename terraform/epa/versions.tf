terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80.0"
    }
  }

  backend "s3" {
    bucket       = "airfire-cicd-tfstate-339712853872-us-west-2"
    key          = "codebuild-runner/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = {
      Project   = "airfire-cicd"
      ManagedBy = "terraform"
      Component = "github-actions-runner-epa"
    }
  }
}
