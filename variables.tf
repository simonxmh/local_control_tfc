variable "hostname" {
  type = string
}

variable "github_oauth_token" {
  type = string
}

variable "organization" {
  type = string
}

variable "branch" {
  type = string
}

variable "user_email" {
  type = string
}

variable "repo" {
  type = string
}

variable "tfc_cred_key" {
  type = string
}

variable "tfc_cred_token" {
  type = string
}

variable "random_var" {
  type = string
  default = "test_Var"
}

# variable "agent_pool_id" {
#   type = string
# }

variable "num_instance" {
  type = number
}
