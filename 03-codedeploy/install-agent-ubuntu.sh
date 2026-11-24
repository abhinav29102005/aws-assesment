#!/usr/bin/env bash
# Run on the Ubuntu EC2 instance after attaching its approved instance profile.
set -euo pipefail
: "${AWS_REGION:?Set AWS_REGION to the instance region}"
sudo apt-get update
sudo apt-get install -y wget curl ca-certificates
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
cd "$work_dir"
wget -q "https://aws-codedeploy-${AWS_REGION}.s3.${AWS_REGION}.amazonaws.com/latestv2/install"
chmod +x install
sudo ./install auto
sudo systemctl enable --now codedeploy-agent
sudo systemctl status codedeploy-agent --no-pager
# Install a supported Node.js 22+ runtime as /usr/bin/node before deploying.
# Verify with: /usr/bin/node --version
