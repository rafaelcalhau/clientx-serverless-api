terraform {
  required_version = "~>1.5.7"

  backend "s3" {
    bucket         = "calhausoft-remote-settings"
    key            = "terraform/clientx/statefile.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_caller_identity" "current" {}