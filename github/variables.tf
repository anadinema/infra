variable "github_token" {
  type      = string
  sensitive = true
}

variable "onepass_sa_token" {
  type      = string
  sensitive = true
}

locals {
  repos_config = yamldecode(file("infra.yml"))

  repositories = try(local.repos_config.repositories, [])
  owner_user   = try(local.repos_config.owner, null)

  repo_users = flatten([
    for repo in local.repositories : [
      for user in try(repo.users, []) : {
        repo       = repo.name
        username   = user.name
        permission = user.permissions
      }
    ]
  ])

  repo_variables = flatten([
    for repo in local.repositories : [
      for v in try(repo.variables, []) : {
        repo  = repo.name
        name  = v.name
        value = v.value
      }
    ]
  ])

  repo_secrets = flatten([
    for repo in local.repositories : [
      for secret in try(repo.secrets, []) : {
        repo        = repo.name
        secret_name = secret.name
        value       = try(secret.value, null)
        onepass_key = try(secret.onePassItem, null)
      }
    ]
  ])

  repo_environments = flatten([
    for repo in local.repositories : [
      for env in try(repo.environments, []) : {
        repo            = repo.name
        env_name        = env.name
        secrets         = try(env.secrets, [])
        approval_needed = try(env.approveDeployment, false)
      }
    ]
  ])

  repo_environment_secrets = flatten([
    for repo in local.repositories : [
      for env in try(repo.environments, []) : [
        for secret in try(env.secrets, []) : {
          repo        = repo.name
          env_name    = env.name
          secret_name = secret.name
          value       = try(secret.value, null)
          onepass_key = try(secret.onePassItem, null)
        }
      ]
    ]
  ])

  repo_environment_variables = flatten([
    for repo in local.repositories : [
      for env in try(repo.environments, []) : [
        for v in try(env.variables, []) : {
          repo     = repo.name
          env_name = env.name
          var_name = v.name
          value    = v.value
        }
      ]
    ]
  ])

  repo_default_branch_rules = flatten([
    for repo in local.repositories : (
      try(repo.addDefaultBranchRules, true) == true ? [
        {
          repo            = repo.name
          repo_visibility = try(repo.visibility, "public")
          branch          = "main"
        }
    ] : [])
  ])

}
