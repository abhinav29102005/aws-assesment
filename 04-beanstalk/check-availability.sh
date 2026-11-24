#!/usr/bin/env bash
set -uo pipefail
: "${APP_URL:?Set APP_URL to the Beanstalk URL}"
for ((i=1;i<=180;i++)); do
  result=$(curl -sS --max-time 5 -o /dev/null -w '%{http_code}' "${APP_URL%/}/health")
  printf '%s %s\n' "$(date -u +%FT%TZ)" "$result"
  sleep 2
done
