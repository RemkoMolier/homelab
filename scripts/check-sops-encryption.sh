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
#   With no arguments, checks all SOPS files tracked by git.
#   File patterns are read from .sops.yaml in the repository root.

set -euo pipefail

ENC_PATTERN='^ENC\[AES256_GCM,data:.+,iv:.+,tag:.+,type:(str|int|float|bytes|bool|comment)\]$'
errors=0

# Locate repository root and .sops.yaml
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel 2>/dev/null)" \
  || { echo "ERROR: not inside a git repository."; exit 1; }
SOPS_YAML="${REPO_ROOT}/.sops.yaml"

if [[ ! -f "${SOPS_YAML}" ]]; then
  echo "No .sops.yaml found at ${SOPS_YAML}; nothing to check."
  exit 0
fi

# Extract path_regex patterns from .sops.yaml
mapfile -t SOPS_PATTERNS < <(
  python3 -c "
import re, sys
with open(sys.argv[1]) as f:
    content = f.read()
for m in re.finditer(r\"path_regex:\s*['\\\"]?([^'\\\"\\n]+)['\\\"]?\", content):
    print(m.group(1).strip())
" "${SOPS_YAML}"
)

if [[ ${#SOPS_PATTERNS[@]} -eq 0 ]]; then
  echo "No path_regex entries found in ${SOPS_YAML}; nothing to check."
  exit 0
fi

# Return 0 if the file path matches any SOPS creation rule pattern.
# The .sops.yaml config file itself is always excluded.
is_sops_file() {
  local file="${1#./}"
  [[ "${REPO_ROOT}/${file}" -ef "${SOPS_YAML}" ]] && return 1
  python3 -c "
import re, sys
path, patterns = sys.argv[1], sys.argv[2:]
sys.exit(0 if any(re.search(p, path) for p in patterns) else 1)
" "${file}" "${SOPS_PATTERNS[@]}"
}

# Load a JSON or YAML file and return parsed data
load_file() {
  python3 -c "
import json, sys, os

path = sys.argv[1]
ext = os.path.splitext(path)[1].lower()

with open(path) as f:
    if ext in ('.yaml', '.yml'):
        try:
            import yaml
        except ImportError:
            print('ERROR: PyYAML not installed; cannot check YAML files', file=sys.stderr)
            sys.exit(2)
        data = yaml.safe_load(f)
    else:
        data = json.load(f)

json.dump(data, sys.stdout)
" "$1"
}

check_all_values() {
  local file="$1"
  local plaintext
  plaintext=$(load_file "$file" | python3 -c "
import json, sys, re

ENC = re.compile(r'''${ENC_PATTERN}''')

def check(obj, path=''):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == 'sops':
                continue
            check(v, f'{path}.{k}' if path else k)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            check(v, f'{path}[{i}]')
    elif isinstance(obj, str):
        if obj == '':
            return
        if not ENC.match(obj):
            print(f'{path}: {obj[:40]}...' if len(obj) > 40 else f'{path}: {obj}')
    elif obj is not None:
        rendered = json.dumps(obj)
        print(f'{path}: {rendered}')

data = json.load(sys.stdin)
check(data)
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
  plaintext=$(load_file "$file" | python3 -c "
import json, sys, re

ENC = re.compile(r'''${ENC_PATTERN}''')

def check_leaves(obj, path):
    if isinstance(obj, dict):
        for k, v in obj.items():
            check_leaves(v, f'{path}.{k}')
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            check_leaves(v, f'{path}[{i}]')
    elif isinstance(obj, str):
        if obj == '':
            return
        if not ENC.match(obj):
            print(f'{path}: {obj[:40]}...' if len(obj) > 40 else f'{path}: {obj}')
    elif obj is not None:
        rendered = json.dumps(obj)
        print(f'{path}: {rendered}')

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

data = json.load(sys.stdin)
find_secrets(data)
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
  files=()
  for f in "$@"; do
    is_sops_file "$f" && files+=("$f") || true
  done
else
  mapfile -t files < <(
    git -C "${REPO_ROOT}" ls-files \
      | while IFS= read -r f; do
          [[ -f "${REPO_ROOT}/${f}" ]] && is_sops_file "${f}" && echo "${REPO_ROOT}/${f}" || true
        done \
      | sort
  )
fi

for file in "${files[@]}"; do
  # Skip files that don't exist (deleted in working tree)
  [[ -f "$file" ]] || continue

  # Skip unsupported file types
  [[ "$file" == *.json || "$file" == *.yaml || "$file" == *.yml ]] || continue

  basename=$(basename "$file")

  if [[ "$basename" == .env.sops.* ]]; then
    # Full encryption — check all values
    check_all_values "$file" || ((errors++))
  elif [[ "$file" == *.sops.json || "$file" == *.sops.yaml || "$file" == *.sops.yml ]]; then
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
