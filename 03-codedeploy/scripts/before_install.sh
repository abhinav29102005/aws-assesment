#!/usr/bin/env bash
set -euo pipefail
command -v node >/dev/null
node -e "if(Number(process.versions.node.split('.')[0])<22) process.exit(1)"
id academyapp >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin academyapp
install -d -o academyapp -g academyapp /opt/academy-app
