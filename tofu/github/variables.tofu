variable "github_token" {
  type      = string
  sensitive = true
}

variable "onepass_sa_token" {
  type      = string
  sensitive = true
}

locals {
  repos_config = yamldecode(file("config/infra.yml"))

  repositories     = try(local.repos_config.repositories, [])
  owner_user       = try(local.repos_config.owner, null)
  owner_name       = try(local.repos_config.owner_name, null)
  current_year     = try(local.repos_config.current_year, null)
  global_templates = try(local.repos_config.global_template_dirs, [])

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
        onepass_key = try(secret.op_item, null)
      }
    ]
  ])

  repo_environments = flatten([
    for repo in local.repositories : [
      for env in try(repo.environments, []) : {
        repo            = repo.name
        env_name        = env.name
        secrets         = try(env.secrets, [])
        approval_needed = try(env.enable_deployment_approval, false)
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
          onepass_key = try(secret.op_item, null)
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
      try(repo.enable_default_branch_rules, true) == true ? [
        {
          repo            = repo.name
          repo_visibility = try(repo.visibility, "public")
          branch          = "main"
        }
    ] : [])
  ])

  repo_managed_template_files = flatten([
    for repo in local.repositories : [
      for template_root in try(concat(repo.template_dirs, local.global_templates), []) : [
        for template_relative_path in fileset(template_root, "**") : {
          repo                   = repo.name
          template_relative_path = template_relative_path
          source_path            = "${template_root}/${template_relative_path}"
          destination_path       = trimsuffix(template_relative_path, ".tftpl")
          is_tftpl               = endswith(template_relative_path, ".tftpl")
          template_vars = merge(try(repo.template_vars, {}), {
            author         = local.owner_name,
            codeowners     = format("@%s", local.owner_user),
            current_year   = local.current_year,
            inception_year = try(repo.inception_year, null)
          })
        }
      ]
    ]
  ])
}
