#!/usr/bin/env bash
# Create the intermediate CA key and certificate, signed by the root CA.
# Run once. The intermediate CA is used by Terraform to issue device certs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root-ca"
INTER_DIR="${SCRIPT_DIR}/../intermediate-ca"

if [ ! -f "${ROOT_DIR}/ca.key" ] || [ ! -f "${ROOT_DIR}/ca.crt" ]; then
  echo "Root CA not found. Run init-root-ca.sh first."
  exit 1
fi

if [ -f "${INTER_DIR}/ca.key" ]; then
  echo "Intermediate CA key already exists at ${INTER_DIR}/ca.key"
  echo "Delete it manually if you want to regenerate."
  exit 1
fi

echo "Generating intermediate CA private key..."
openssl genrsa -out "${INTER_DIR}/ca.key" 4096

echo "Generating intermediate CA CSR..."
openssl req -new \
  -key "${INTER_DIR}/ca.key" \
  -config "${INTER_DIR}/openssl.cnf" \
  -out "${INTER_DIR}/ca.csr"

echo "Signing intermediate CA certificate with root CA (10 year validity)..."
openssl x509 -req \
  -in "${INTER_DIR}/ca.csr" \
  -CA "${ROOT_DIR}/ca.crt" \
  -CAkey "${ROOT_DIR}/ca.key" \
  -CAcreateserial \
  -extfile "${INTER_DIR}/openssl.cnf" \
  -extensions v3_intermediate_ca \
  -days 3650 \
  -sha256 \
  -out "${INTER_DIR}/ca.crt"

# Create the full chain (intermediate + root)
cat "${INTER_DIR}/ca.crt" "${ROOT_DIR}/ca.crt" > "${INTER_DIR}/ca-chain.crt"

# Clean up CSR
rm -f "${INTER_DIR}/ca.csr"

echo "Intermediate CA created:"
openssl x509 -in "${INTER_DIR}/ca.crt" -noout -subject -issuer -dates

echo ""
echo "Chain file: ${INTER_DIR}/ca-chain.crt"
echo "Terraform will use the intermediate CA key to issue device certificates."
