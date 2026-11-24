#!/usr/bin/env bash
set -euo pipefail
if systemctl cat academy-app.service >/dev/null 2>&1; then systemctl stop academy-app.service; fi
