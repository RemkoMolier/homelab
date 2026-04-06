resource "github_repository" "homelab" {
  name        = "homelab"
  description = "Infrastructure-as-code for Remko's homelab"
  visibility  = "public"

  # Features
  has_issues   = true
  has_wiki     = false
  has_projects = false

  # Merge strategy — rebase only to preserve atomic commit discipline
  allow_squash_merge = false
  allow_merge_commit = false
  allow_rebase_merge = true

  # Branch hygiene
  delete_branch_on_merge = true
  allow_update_branch    = true
  allow_auto_merge       = true

  # Security
  vulnerability_alerts = true
  archive_on_destroy   = true

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
}

resource "github_actions_secret" "sops_age_key" {
  repository      = github_repository.homelab.name
  secret_name     = "SOPS_AGE_KEY"
  plaintext_value = local.secrets["sops_age_key"]
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.homelab.node_id
  pattern       = "main"

  # Block force-pushes and branch deletion
  allows_deletions    = false
  allows_force_pushes = false

  # Admin can bypass PR requirement when needed
  enforce_admins = false

  # All CI checks must pass before merge
  required_status_checks {
    strict = true
    contexts = [
      "Markdown",
      "Terraform",
      "Secret scanning",
      "SOPS encryption check",
    ]
  }

  # PRs required, but admin can bypass
  required_pull_request_reviews {
    required_approving_review_count = 0
    dismiss_stale_reviews           = false
  }
}
