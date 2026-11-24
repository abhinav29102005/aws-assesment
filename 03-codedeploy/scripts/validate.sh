#!/usr/bin/env bash
set -euo pipefail
for attempt in {1..20}; do
  if curl --fail --silent http://127.0.0.1:8080/health | /usr/bin/node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{try{process.exit(JSON.parse(s).status==="ok"?0:1)}catch{process.exit(1)}})'; then exit 0; fi
  sleep 2
done
exit 1
