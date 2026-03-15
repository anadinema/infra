# Create GitHub repositories with specific configurations
# tf import 'github_repository.repositories["dotfiles"]' dotfiles
resource "github_repository" "repositories" {
  for_each = { for repo in local.repositories : repo.name => repo }

  name             = each.value.name
  description      = each.value.description
  homepage_url     = try(each.value.homepage, null)
  license_template = "mit"
  visibility       = try(each.value.visibility, "public")

  has_projects    = false
  has_issues      = true
  has_wiki        = try(each.value.enableWiki, false)
  has_discussions = false

  # Needed to set a default branch
  auto_init = true

  # Merge, rebase, squash rules
  allow_merge_commit          = false
  delete_branch_on_merge      = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  allow_auto_merge = try(each.value.autoMergePr, false)

  allow_update_branch = true

  # Merge defaultTags with repo-specific tags
  topics = try(each.value.tags, [])

  archived           = false
  archive_on_destroy = false

  vulnerability_alerts = false

  dynamic "security_and_analysis" {
    for_each = try(each.value.visibility, "public") == "public" ? [1] : []
    content {
      # Enable secret_scanning only for all repositories
      secret_scanning {
        status = "enabled"
      }

      # Enable secret scanning push protection for all repositories
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

}


resource "github_repository_file" "add_code_owners_file" {
  for_each = { for repo in local.repositories : repo.name => repo }

  repository          = github_repository.repositories[each.key].name
  file                = ".github/CODEOWNERS"
  branch              = "main"
  content             = format("* @%s", local.owner_user)
  commit_message      = "[skip ci] Add CODEOWNERS file"
  overwrite_on_create = true
}

resource "github_actions_variable" "repository_variables" {
  for_each = {
    for v in local.repo_variables : "${v.repo}:${v.name}" => v
  }

  repository    = github_repository.repositories[each.value.repo].name
  variable_name = each.value.name
  value         = each.value.value
}

# Set secrets in the given repository.
# Secrets are either plain text value from .yml or fetched from 1Password
# and assigned to the corresponding repository.
resource "github_actions_secret" "repository_secrets" {
  for_each = {
    for s in local.repo_secrets :
    "${s.repo}:${s.secret_name}" => s
  }

  repository  = github_repository.repositories[each.value.repo].name
  secret_name = each.value.secret_name

  plaintext_value = (
    try(each.value.onepass_key, null) != null
    ? data.onepassword_item.vault_repo_secrets["${each.value.repo}:${each.value.secret_name}"].password
    : each.value.value
  )
}

# Protect the default branch with some rules
resource "github_branch_protection" "default_branch_rules" {
  for_each = {
    for rule in local.repo_default_branch_rules :
    rule.repo => rule
    if rule.repo_visibility != "private"
  }

  repository_id = github_repository.repositories[each.value.repo].node_id
  pattern       = each.value.branch

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    restrict_dismissals             = false
  }

  force_push_bypassers = [data.github_user.current.node_id]

  required_linear_history = true
  enforce_admins          = false
  allows_deletions        = false
  allows_force_pushes     = false
}

# Provide access to users to this repository apart from me
resource "github_repository_collaborator" "user_access" {
  for_each = {
    for user in local.repo_users : "${user.repo}:${user.username}" => user
    if local.repo_users != null && length(local.repo_users) > 0
  }

  repository = github_repository.repositories[each.value.repo].name
  username   = each.value.username
  permission = each.value.permission
}
