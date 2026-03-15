# Creates GitHub repository environments dynamically
# for a list of environments defined in the yml file.
resource "github_repository_environment" "deployment_envs" {
  for_each = {
    for env in local.repo_environments : "${env.repo}:${env.env_name}" => env
  }

  environment = each.value.env_name
  repository  = github_repository.repositories[each.value.repo].name

  # Only add reviewers if approval is required
  dynamic "reviewers" {
    for_each = each.value.approval_needed == true ? [1] : []
    content {
      users = [data.github_user.current.id]
    }
  }
}

# Set variables for each GitHub environment in the given repository.
resource "github_actions_environment_variable" "deployment_env_variables" {
  for_each = {
    for v in local.repo_environment_variables :
    "${v.repo}:${v.env_name}:${v.var_name}" => v
  }

  repository    = github_repository.repositories[each.value.repo].name
  environment   = each.value.env_name
  variable_name = each.value.var_name
  value         = each.value.value
}

# Set secrets for each GitHub environment in the given repository.
# Secrets are either plain text value from .yml or fetched from 1Password
# and assigned to the appropriate environment in the corresponding repository.
resource "github_actions_environment_secret" "deployment_env_secrets" {
  for_each = {
    for s in local.repo_environment_secrets :
    "${s.repo}:${s.env_name}:${s.secret_name}" => s
  }

  repository  = github_repository.repositories[each.value.repo].name
  environment = each.value.env_name
  secret_name = each.value.secret_name

  plaintext_value = (
    try(each.value.onepass_key, null) != null
    ? data.onepassword_item.vault_env_secrets["${each.value.repo}:${each.value.env_name}:${each.value.secret_name}"].password
    : each.value.value
  )
}
