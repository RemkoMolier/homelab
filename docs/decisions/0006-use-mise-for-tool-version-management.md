---
status: accepted
date: 2026-04-03
decision-makers: Remko Molier
---

# Use mise for tool version management

## Context and Problem Statement

The homelab repository needs specific versions of CLI tools (currently markdownlint-cli2 and commitlint, later IaC tools like Terraform and kubectl).
Without version pinning, contributors and AI agents may use different tool versions, causing inconsistent results.
The solution must work across local development, CI, and Claude web — where Docker and devcontainers are not available.

## Decision Drivers

- Tool versions must be pinned in the repository and reproducible across environments
- The solution must work on Claude web (Ubuntu 24.04 sandbox with root access but no Docker)
- The config file should be non-blocking — the repo must remain usable without the version manager installed
- The tool should scale from linting tools today to IaC tools (Terraform, kubectl, Helm) later
- Installation should be simple and fast, especially in ephemeral environments

## Considered Options

- mise (polyglot version manager)
- devbox (Nix-based reproducible environments)
- asdf (plugin-based version manager)
- aqua (CLI-focused version manager)
- npm-only (package.json for everything)

## Decision Outcome

Chosen option: "mise", because it provides the best balance of simplicity, portability, and capability.
It installs as a single binary without root, manages both language runtimes and CLI tools (including npm packages via its npm backend), and its `mise.toml` config file is human-readable documentation even without mise installed.
A setup script bootstraps mise automatically on Claude web sessions.

### Consequences

- Good, because one tool manages Node.js versions, npm-based linters, and future IaC CLIs
- Good, because `mise.toml` is readable and non-blocking — the repo works without mise
- Good, because single-binary installation takes seconds, ideal for ephemeral environments
- Good, because asdf-compatible — can export `.tool-versions` if needed
- Good, because built-in task runner and env var management reduce the need for make/direnv
- Bad, because an additional tool to install beyond what the OS provides
- Neutral, because the npm backend for linting tools may not handle custom markdownlint plugins — a package.json fallback is available if needed

### Confirmation

`mise install` succeeds and `mise exec -- markdownlint-cli2 --help` runs the correct version.
The setup script installs mise and tools without manual intervention on Claude web.

## Pros and Cons of the Options

### mise

Rust-based polyglot version manager with npm backend, task runner, and env var management.

- Good, because single binary, no root required, ~5-10ms overhead
- Good, because 23k+ GitHub stars, 150+ contributors, very active development
- Good, because npm backend manages Node.js CLI tools without a package.json
- Good, because built-in task runner can replace make for project scripts
- Bad, because younger project than asdf (though now larger by stars)

### devbox (Nix-based)

Wraps the Nix package manager behind a simple JSON config.

- Good, because most reproducible option — Nix guarantees identical environments
- Good, because built-in devcontainer generation
- Good, because access to 80k+ Nix packages
- Bad, because requires Nix daemon installation (non-trivial, slow cold start)
- Bad, because devcontainers don't work on Claude web (no Docker)
- Bad, because Nix package version strings don't map to upstream release versions
- Bad, because officially requires root for installation

### asdf

Plugin-based version manager, rewritten in Go in v0.16.

- Good, because pioneer of `.tool-versions` format, large plugin ecosystem
- Good, because Go rewrite improved performance significantly
- Bad, because mise is a strict superset with better performance and security
- Bad, because no built-in env var management or task runner

### aqua

Declarative CLI version manager focused on DevOps tools.

- Good, because purpose-built for CLI tool management
- Good, because strong Renovate integration for automated updates
- Bad, because smallest community (~1.6k stars), primarily one maintainer
- Bad, because no language runtime management (Node.js, Python)

### npm-only

Use package.json devDependencies for all tools.

- Good, because zero additional tooling — Node.js is pre-installed everywhere
- Good, because familiar to any JavaScript developer
- Bad, because cannot manage non-Node.js tools (Terraform, kubectl)
- Bad, because requires Node.js even when the project tools are not Node-based

## More Information

- [mise documentation](https://mise.jdx.dev/)
- [mise GitHub repository](https://github.com/jdx/mise)
- [mise npm backend](https://mise.jdx.dev/dev-tools/backends/npm.html)
- [mise comparison to asdf](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html)
- [mise GitHub Action](https://github.com/jdx/mise-action) — for future CI integration
