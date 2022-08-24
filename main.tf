terraform {
  required_providers {
    tfe = {
      version  = "~> 0.35.0"
    }
  }
}

provider "tfe" {
  hostname = var.hostname
  token = var.tfc_cred_token
}

data "tfe_organization_membership" "user" {
  organization  = var.organization
  email = var.user_email
}

resource "tfe_oauth_client" "oauth" {
  organization = var.organization
  api_url = "https://api.github.com"
  http_url = "https://github.com"
  oauth_token = var.github_oauth_token
  service_provider = "github"
}

resource "tfe_workspace" "parent" {
  organization = var.organization
  name = "Parent"
  auto_apply = true
  queue_all_runs = true

  vcs_repo {
    identifier = var.repo
    branch = var.branch
    oauth_token_id = tfe_oauth_client.oauth.oauth_token_id
  }
}

// token_key should be a value based on the rules here : https://www.terraform.io/cli/config/config-file#environment-variable-credentials
// token_value should be the same token you use to apply this config from the CLI.

resource "tfe_variable" "token" {
  key = "TFE_TOKEN"
  value = var.tfc_cred_token
  category = "env"
  sensitive = "true"
  workspace_id = tfe_workspace.parent.id
  description = "This allows the build agent to call back to TFC when executing plans and applies"
}

resource "tfe_variable" "organization" {
  key = "organization"
  value = var.organization
  category = "terraform"
  workspace_id = tfe_workspace.parent.id
  description = "Passing along the var settings from this config to the config that parent workspace will use to generate the child workspace"
}

resource "tfe_variable" "hostname" {
  key = "hostname"
  value = var.hostname
  category = "terraform"
  workspace_id = tfe_workspace.parent.id
  description = "Passing along the var settings from this config to the config that parent workspace will use to generate the child workspace"
}
