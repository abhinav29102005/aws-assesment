#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
node <<'JS'
const fs = require('fs');
const path = 'app.test.js';
fs.writeFileSync(path, fs.readFileSync(path, 'utf8').replace("assert.equal(body.version,'1.0.0')", "assert.equal(body.version,'9.9.9')"));
JS
echo 'Commit the test change to a demo branch and open a PR. Revert it after capturing failure.'
