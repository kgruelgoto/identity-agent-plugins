#!/bin/bash
# Project dashboard generator
# Creates JSON dashboard with key metrics

set -euo pipefail

if ! command -v jira &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: jira-cli and jq required"
    exit 1
fi

OUTPUT_FILE="${1:-dashboard.json}"

# Get all open issues (not Done status category)
jira issue list --raw 2>/dev/null | jq '[.[] | select(.fields.status.statusCategory.key != "done")] | {
    total: length,
    by_status: [group_by(.fields.status.name)[] | {
        status: .[0].fields.status.name,
        count: length
    }],
    unassigned: [.[] | select(.fields.assignee.displayName == "")] | length,
    high_priority: [.[] | select(.fields.priority.name == "High" or .fields.priority.name == "Highest")] | length
}' > "$OUTPUT_FILE"

echo "Dashboard saved to: $OUTPUT_FILE"
cat "$OUTPUT_FILE"
