#!/usr/bin/env bash
set -euo pipefail
chown -R academyapp:academyapp /opt/academy-app
chmod 644 /opt/academy-app/app.js /opt/academy-app/package.json /etc/systemd/system/academy-app.service
systemctl daemon-reload
systemctl enable academy-app.service
