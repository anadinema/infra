terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
    onepassword = {
      source = "1Password/onepassword"
    }
  }
  backend "s3" {
    region               = "eu-north-1"
    workspace_key_prefix = "wsp"
    bucket               = "opentf-infra-state"
    key                  = "tfstate/github/terraform.tfstate"
    use_lockfile         = true
    encrypt              = true
  }
}

provider "github" {
  token = var.github_token
}

provider "onepassword" {
  service_account_token = var.onepass_sa_token
}
