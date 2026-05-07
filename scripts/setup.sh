#!/usr/bin/env bash
# Spin up a fresh scratch org for the developer practical exam.
set -euo pipefail

ALIAS="${1:-practical-exam}"
DURATION="${2:-7}"

echo "Creating scratch org: $ALIAS (duration: $DURATION days)"
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias "$ALIAS" \
  --duration-days "$DURATION" \
  --target-dev-hub corehc-prod \
  --set-default

echo "Deploying source..."
sf project deploy start --target-org "$ALIAS"

echo "Assigning Practical Exam permission set..."
sf org assign permset --name Practical_Exam --target-org "$ALIAS"

echo "Generating default password..."
sf org generate password --target-org "$ALIAS"
sf org display user --target-org "$ALIAS"

echo "Opening org..."
sf org open --target-org "$ALIAS"

echo
echo "Done. To seed data (will FAIL until Exercise 1 is fixed):"
echo "  sf apex run --file scripts/apex/seed.apex --target-org $ALIAS"
