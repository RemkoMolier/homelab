#!/usr/bin/env bash
# Create the root CA key and self-signed certificate.
# Run once. The root CA key is encrypted by git-crypt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root-ca"

if [ -f "${ROOT_DIR}/ca.key" ]; then
  echo "Root CA key already exists at ${ROOT_DIR}/ca.key"
  echo "Delete it manually if you want to regenerate."
  exit 1
fi

echo "Generating root CA private key..."
openssl genrsa -out "${ROOT_DIR}/ca.key" 4096

echo "Generating root CA certificate (20 year validity)..."
openssl req -new -x509 \
  -key "${ROOT_DIR}/ca.key" \
  -config "${ROOT_DIR}/openssl.cnf" \
  -extensions v3_ca \
  -days 7300 \
  -out "${ROOT_DIR}/ca.crt"

echo "Root CA created:"
openssl x509 -in "${ROOT_DIR}/ca.crt" -noout -subject -dates

echo ""
echo "IMPORTANT: The root CA key at ${ROOT_DIR}/ca.key is encrypted by git-crypt."
echo "Make sure git-crypt is unlocked before committing."
