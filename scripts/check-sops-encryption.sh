#!/usr/bin/env bash
# Verify that SOPS-encrypted files have all expected values encrypted.
#
# For *.sops.json / *.sops.yaml (encrypted_regex: "^secrets$"):
#   All leaf values under keys named "secrets" must be SOPS ENC blobs or empty.
#
# For .env.sops.json (full encryption):
#   All leaf values must be SOPS ENC blobs or empty.
#
# Usage: scripts/check-sops-encryption.sh [file ...]
#   With no arguments, checks all SOPS files in the repository.

set -euo pipefail

ENC_PATTERN='^ENC\[AES256_GCM,data:.+,iv:.+,tag:.+,type:(str|int|float|bytes|bool|comment)\]$'
errors=0

check_all_values() {
  local file="$1"
  local plaintext
  plaintext=$(python3 -c "
import json, sys

def check(obj, path=''):
    if isinstance(obj, dict):
        # Skip SOPS metadata
        if 'sops' == path.split('.')[-1]:
            return
        for k, v in obj.items():
            if k == 'sops':
                continue
            check(v, f'{path}.{k}' if path else k)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            check(v, f'{path}[{i}]')
    elif isinstance(obj, str) and obj != '':
        import re
        if not re.match(r'''${ENC_PATTERN}''', obj):
            print(f'{path}: {obj[:40]}...' if len(obj) > 40 else f'{path}: {obj}')

with open('$file') as f:
    check(json.load(f))
" 2>&1)

  if [[ -n "$plaintext" ]]; then
    echo "ERROR: $file has unencrypted values:"
    echo "$plaintext" | sed 's/^/  /'
    return 1
  fi
  return 0
}

check_secrets_keys() {
  local file="$1"
  local plaintext
  plaintext=$(python3 -c "
import json, sys, re

ENC = re.compile(r'''${ENC_PATTERN}''')

def check_leaves(obj, path):
    if isinstance(obj, dict):
        for k, v in obj.items():
            check_leaves(v, f'{path}.{k}')
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            check_leaves(v, f'{path}[{i}]')
    elif isinstance(obj, str) and obj != '':
        if not ENC.match(obj):
            print(f'{path}: {obj[:40]}...' if len(obj) > 40 else f'{path}: {obj}')

def find_secrets(obj, path=''):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == 'sops':
                continue
            p = f'{path}.{k}' if path else k
            if k == 'secrets':
                check_leaves(v, p)
            else:
                find_secrets(v, p)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            find_secrets(v, f'{path}[{i}]')

with open('$file') as f:
    find_secrets(json.load(f))
" 2>&1)

  if [[ -n "$plaintext" ]]; then
    echo "ERROR: $file has unencrypted secrets:"
    echo "$plaintext" | sed 's/^/  /'
    return 1
  fi
  return 0
}

# Collect files to check
if [[ $# -gt 0 ]]; then
  files=("$@")
else
  mapfile -t files < <(find . \( -name '*.sops.json' -o -name '*.sops.yaml' \) ! -name '.sops.yaml' 2>/dev/null | sort)
fi

for file in "${files[@]}"; do
  # Skip files that don't exist (deleted in working tree)
  [[ -f "$file" ]] || continue

  # Skip non-JSON/YAML files
  [[ "$file" == *.json || "$file" == *.yaml ]] || continue

  basename=$(basename "$file")

  if [[ "$basename" == .env.sops.* ]]; then
    # Full encryption — check all values
    check_all_values "$file" || ((errors++))
  elif [[ "$file" == *.sops.json || "$file" == *.sops.yaml ]]; then
    # Partial encryption — check only secrets keys
    check_secrets_keys "$file" || ((errors++))
  fi
done

if [[ $errors -gt 0 ]]; then
  echo ""
  echo "Found $errors file(s) with unencrypted values."
  echo "Run 'sops -e -i <file>' to encrypt."
  exit 1
fi

echo "All SOPS files are properly encrypted."
exit 0
