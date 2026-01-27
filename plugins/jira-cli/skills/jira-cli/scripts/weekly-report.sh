#!/bin/bash
# Weekly activity report
# Shows issues created and completed this week

set -euo pipefail

if ! command -v jira &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: jira-cli and jq required"
    exit 1
fi

CREATED=$(jira issue list --created -7d --raw 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
COMPLETED=$(jira issue list -s"Done" --created -7d --raw 2>/dev/null | jq 'length' 2>/dev/null || echo "0")

echo "=== Weekly Report ==="
echo "Week of $(date +%Y-%m-%d)"
echo
echo "Created: $CREATED"
echo "Completed: $COMPLETED"
echo "Net: $((CREATED - COMPLETED))"
echo
echo "=== Completed This Week ==="
jira issue list -s"Done" --created -7d --plain 2>/dev/null || echo "None"
