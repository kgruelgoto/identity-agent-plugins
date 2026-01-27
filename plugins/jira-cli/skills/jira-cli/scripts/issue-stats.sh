#!/bin/bash
# Issue statistics generator
# Shows summary metrics across the project

set -euo pipefail

if ! command -v jira &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: jira-cli and jq required"
    exit 1
fi

ALL_ISSUES=$(jira issue list --raw 2>/dev/null || echo "[]")

echo "=== Project Statistics ==="
echo
echo "Total Open: $(echo "$ALL_ISSUES" | jq '[.[] | select(.fields.status.statusCategory.key != "done")] | length')"
echo "Completed This Week: $(jira issue list -s"Done" --created -7d --raw 2>/dev/null | jq 'length' 2>/dev/null || echo "0")"
echo "High Priority Open: $(echo "$ALL_ISSUES" | jq '[.[] | select(.fields.priority.name == "High" or .fields.priority.name == "Highest")] | length')"
echo "Unassigned: $(echo "$ALL_ISSUES" | jq '[.[] | select(.fields.assignee.displayName == "")] | length')"
echo
echo "=== Status Distribution ==="
echo "$ALL_ISSUES" | jq -r '
group_by(.fields.status.name) |
sort_by(-length) |
.[] |
"\(.[0].fields.status.name): \(length)"' 2>/dev/null || echo "No data"
