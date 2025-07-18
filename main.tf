terraform {
  required_providers {
    tfe = {
      version  = "= 0.67.1"
    }
  }
}

# Use terraform random_pet provider to generate a random name  
resource "random_pet" "random_name" {
  length    = "2"
  separator = "-"
  count     = var.num_instance
}

provider "tfe" {
  hostname = var.hostname
  token = var.tfc_cred_token
  ssl_skip_verify = true
}


##################### RESOURCES ########################

resource "tfe_oauth_client" "github" {
  name = "my-github-oauth-client"
  organization = var.organization
  api_url = "https://api.github.com"
  http_url = "https://github.com"
  oauth_token = var.github_oauth_token
  service_provider = "github"
  organization_scoped = true
}

resource "tfe_project" "test" {
  organization = var.organization
  name = "project3"
  auto_destroy_activity_duration = "1h"
}

# resource "tfe_team" "example" {
#   name         = "example-team"
#   organization = var.organization
# }

# resource "tfe_organization_membership" "test" {
#   organization = var.organization
#   email        = "test.member@company.com"
# }

# resource "tfe_team_notification_configuration" "test" {
#   name             = "my-test-email-notification-configuration"
#   enabled          = true
#   destination_type = "email"  
#   # email_user_ids   = [tfe_organization_membership.test.user_id]
#   triggers         = ["change_request:created"]
#   team_id          = tfe_team.example.id
# }

# resource "tfe_team_notification_configuration" "example" {
#   name             = "example"
#   destination_type = "generic"
#   url              = "https://httpstat.us/200"
#   team_id          = tfe_team.example.id
# } 

# module "team_notification_configuration" {
#   source = "./modules/team_notification_configuration"
# }

# module "overriding_workspace" {
#   source = "./modules/overriding_workspace"
# }


resource "tfe_workspace" "parent" {
  organization = var.organization
  count = var.num_instance
  name = "${random_pet.random_name[count.index].id}-${count.index}"
  auto_apply = true
  project_id = tfe_project.test.id
  # queue_all_runs = true
  # auto_destroy_at = "2026-01-02T00:00:00Z"
  vcs_repo {
    identifier = var.repo
    branch = var.branch
    oauth_token_id = tfe_oauth_client.github.oauth_token_id
    # oauth_token_id = var.oauth_token_id
  }
  # execution_mode = "agent"
  # agent_pool_id = var.agent_pool_id
  force_delete = true
}

# // token_key should be a value based on the rules here : https://www.terraform.io/cli/config/config-file#environment-variable-credentials
# // token_value should be the same token you use to apply this config from the CLI.

resource "tfe_variable" "token" {
  count = var.num_instance
  key = "token"
  # key = var.tfc_cred_key
  value = var.tfc_cred_token
  category = "terraform"
  # category = "env"
  sensitive = "true"
  workspace_id = tfe_workspace.parent[count.index].id
  description = "This allows the build agent to call back to TFC when executing plans and applies"
}

resource "tfe_variable" "hostname" {
  count = var.num_instance
  key = "hostname"
  value = var.hostname
  category = "terraform"
  workspace_id = tfe_workspace.parent[count.index].id
  description = "Passing along the var settings from this config to the config that parent workspace will use to generate the child workspace"
}

resource "tfe_variable" "organization" {
  count = var.num_instance
  key = "organization"
  value = var.organization
  category = "terraform"
  workspace_id = tfe_workspace.parent[count.index].id
  description = "Passing along the var settings from this config to the config that parent workspace will use to generate the child workspace"
}

resource "tfe_workspace_run" "ws_run_parent" {
  count = var.num_instance
  workspace_id    = tfe_workspace.parent[count.index].id
  depends_on   = [tfe_variable.hostname]

  apply {
    manual_confirm    = false
    retry_attempts    = 5
    retry_backoff_min = 5
  }

  destroy {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 3
    retry_backoff_min = 10
  }
}

##### MODULES ############# 

# module "empty" {
#   source  = "dasmeta/empty/null"
#   version = "1.0.0"
# }

# module "cloudposse241" {
#   source = "cloudposse/label/null"
#   version = "0.24.1"
# }

# module "eg_prod_bastion" {
#   source = "cloudposse/label/null"
#   version = "0.25.0"

#   namespace  = "eg"
#   stage      = "prod"
#   name       = "bastion"
#   attributes = ["public"]
#   delimiter  = "-"

#   tags = {
#     "BusinessUnit" = "XYZ",
#     "Snapshot"     = "true"
#   }
# }


# module "hello" {
#   source  = "app.staging.terraform.io/soak-test-projects_large-2/hello/random"
#   version = "6.0.0"
#   # insert required variables here
#   hellos = {
#     hello        = "this is a hello"
#     second_hello = "this is again a hello"
#   }
#   some_key = "this_is the key again"
# }

# module "uuid" {
#   source  = "Invicton-Labs/uuid/random"
#   version = "0.2.0"
# }

# module "labels" {
#   source  = "clouddrove/labels/aws"
#   version = "1.3.0"
# }


# module "hello" {
#   source  = "simontest.ngrok.io/hashicorp/hello/random"
#   version = "0.0.1"
#   # insert required variables here
#   hellos = {
#     hello        = "this is a hel·lo"
#     second_hello = "this is again a hello"
#   }
#   some_key = "this_is the key again"
# }
