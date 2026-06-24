#\!/usr/bin/env bash
# Zero-dependency fallback. Same four payloads as run_demo.rb, in order.
# Usage: set the two URLs, then: bash scripts/run-demo.sh
set -euo pipefail

: "${RECIPE_1_WEBHOOK_URL:?set RECIPE_1_WEBHOOK_URL}"
: "${RECIPE_2_WEBHOOK_URL:?set RECIPE_2_WEBHOOK_URL}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/payloads"

post () { echo; echo "== $1 =="; curl -sS -X POST "$2" -H "Content-Type: application/json" -d @"$DIR/$3"; echo; }

post "Amelia intake"        "$RECIPE_1_WEBHOOK_URL" amelia_intake.json;        sleep 2
post "Amelia verification"  "$RECIPE_2_WEBHOOK_URL" amelia_verification.json;  sleep 2
post "Daniel intake"        "$RECIPE_1_WEBHOOK_URL" daniel_intake.json;        sleep 2
post "Daniel verification"  "$RECIPE_2_WEBHOOK_URL" daniel_verification.json
echo; echo "Now click 'Approve Senior Review' in #lci-senior-auth."
