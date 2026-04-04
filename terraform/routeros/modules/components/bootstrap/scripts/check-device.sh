#!/usr/bin/env bash
# Check if a MikroTik device is reachable on its HTTPS REST API.
# Used as an external data source — reads JSON from stdin, writes JSON to stdout.
set -euo pipefail

# Read query from stdin (external data source protocol)
eval "$(jq -r '@sh "HOSTURL=\(.hosturl) USERNAME=\(.username) PASSWORD=\(.password)"')"

# Try to reach the device on HTTPS
if curl -sk --connect-timeout 3 -u "${USERNAME}:${PASSWORD}" \
  "${HOSTURL}/rest/system/identity" &>/dev/null; then
  echo '{"reachable": "true"}'
else
  echo '{"reachable": "false"}'
fi
