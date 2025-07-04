terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }
  backend "s3" {
    bucket         = "dev-shiv-tf-bucket"
    region         = "us-east-1"
    key            = "eks/terraform.tfstate"
    use_lockfile   = true
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws-region
}