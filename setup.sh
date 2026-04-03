#!/usr/bin/env bash
# Bootstrap script for ephemeral environments (Claude web, CI, etc.)
# Installs mise and all project tools defined in mise.toml.

set -euo pipefail

if ! command -v mise &>/dev/null; then
  echo "Installing mise..."
  curl -fsSL https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "Installing project tools..."
mise install --yes

echo "Setup complete. Tools available:"
mise ls
