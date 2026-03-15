data "github_user" "current" {
  username = local.owner_user
}

data "onepassword_vault" "infra_vault" {
  name = "Infra"
}

data "onepassword_item" "vault_env_secrets" {
  for_each = {
    for s in local.repo_environment_secrets :
    "${s.repo}:${s.env_name}:${s.secret_name}" => s
    if s.onepass_key != null
  }

  title = each.value.onepass_key
  vault = data.onepassword_vault.infra_vault.uuid
}

data "onepassword_item" "vault_repo_secrets" {
  for_each = {
    for s in local.repo_secrets :
    "${s.repo}:${s.secret_name}" => s
    if s.onepass_key != null
  }

  title = each.value.onepass_key
  vault = data.onepassword_vault.infra_vault.uuid
}
