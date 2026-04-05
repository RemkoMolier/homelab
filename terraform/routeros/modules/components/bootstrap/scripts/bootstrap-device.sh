#!/usr/bin/env bash
# Bootstrap a fresh MikroTik device via the plain HTTP REST API.
#
# Expected environment variables:
#   BOOTSTRAP_IP   — IP address of the fresh device (e.g., 192.168.88.1 or DHCP lease IP)
#   BOOTSTRAP_USER — Default user on the fresh device (usually "admin")
#   BOOTSTRAP_PASS — Default password (usually empty)
#   TF_USER        — Terraform user to create
#   TF_PASS        — Terraform user password
#   DEVICE_NAME    — Device identifier for logging
#   MGMT_SUBNET    — Subnet allowed to reach management services (default: 172.16.1.0/24)
set -euo pipefail

API="http://${BOOTSTRAP_IP}/rest"
AUTH="${BOOTSTRAP_USER}:${BOOTSTRAP_PASS}"
MGMT_SUBNET="${MGMT_SUBNET:-172.16.1.0/24}"

echo "Bootstrapping ${DEVICE_NAME} at ${BOOTSTRAP_IP}..."

# Helper: POST to the REST API
api_post() {
  local path="$1"
  local data="$2"
  curl -sf -u "${AUTH}" -X POST \
    -H "Content-Type: application/json" \
    -d "${data}" \
    "${API}${path}"
}

# Helper: PUT/PATCH to the REST API
api_patch() {
  local path="$1"
  local data="$2"
  curl -sf -u "${AUTH}" -X PATCH \
    -H "Content-Type: application/json" \
    -d "${data}" \
    "${API}${path}"
}

# 1. Wait for the device to be reachable
echo "  Waiting for HTTP API..."
for i in $(seq 1 30); do
  if curl -sf --connect-timeout 2 -u "${AUTH}" "${API}/system/identity" &>/dev/null; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "  ERROR: Device not reachable after 60s" >&2
    exit 1
  fi
  sleep 2
done

echo "  Device reachable, starting bootstrap..."

# 2. Create the terraform user group
echo "  Creating terraform user group..."
api_post "/user/group/add" \
  '{"name":"terraform","policy":"api,read,write,policy,test,sensitive,web,rest-api"}' \
  || echo "  (group may already exist)"

# 3. Create the terraform user
echo "  Creating terraform user..."
api_post "/user/add" \
  "{\"name\":\"${TF_USER}\",\"group\":\"terraform\",\"password\":\"${TF_PASS}\"}" \
  || echo "  (user may already exist)"

# 4. Generate a self-signed certificate for api-ssl
echo "  Creating self-signed certificate..."
api_post "/certificate/add" \
  "{\"name\":\"api-cert\",\"common-name\":\"${BOOTSTRAP_IP}\",\"key-size\":\"2048\"}" \
  || echo "  (certificate may already exist)"

# Sign the certificate (self-signed)
echo "  Signing certificate..."
api_post "/certificate/sign" \
  '{"number":"api-cert"}' \
  || echo "  (certificate may already be signed)"

# Wait for signing to complete
sleep 2

# 5. Enable HTTPS services with the certificate
echo "  Enabling api-ssl..."
api_patch "/ip/service/api-ssl" \
  "{\"disabled\":\"false\",\"certificate\":\"api-cert\",\"address\":\"${MGMT_SUBNET}\"}"

echo "  Enabling www-ssl..."
api_patch "/ip/service/www-ssl" \
  "{\"disabled\":\"false\",\"certificate\":\"api-cert\",\"address\":\"${MGMT_SUBNET}\"}"

echo "  Restricting SSH..."
api_patch "/ip/service/ssh" \
  "{\"disabled\":\"false\",\"address\":\"${MGMT_SUBNET}\"}"

echo "  Restricting Winbox..."
api_patch "/ip/service/winbox" \
  "{\"disabled\":\"false\",\"address\":\"${MGMT_SUBNET}\"}"

# 6. Disable insecure services
echo "  Disabling plain HTTP..."
api_patch "/ip/service/www" \
  '{"disabled":"true"}'

echo "  Disabling plain API..."
api_patch "/ip/service/api" \
  '{"disabled":"true"}'

echo "  Disabling Telnet..."
api_patch "/ip/service/telnet" \
  '{"disabled":"true"}'

echo "  Disabling FTP..."
api_patch "/ip/service/ftp" \
  '{"disabled":"true"}'

echo "  Bootstrap complete for ${DEVICE_NAME}"
echo "  Device should now be reachable on HTTPS"
