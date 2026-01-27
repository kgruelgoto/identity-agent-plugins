#!/bin/bash
# Sprint planning report generator
# Shows backlog items, in-progress work, and open bugs

set -euo pipefail

if ! command -v jira &> /dev/null; then
    echo "Error: jira-cli not installed"
    exit 1
fi

echo "=== Sprint Planning Report ==="
echo
echo "Backlog Ready for Sprint:"
jira issue list -s"To Do" -y"High,Medium" --plain 2>/dev/null || echo "None"
echo
echo "In Progress Items:"
jira issue list -s"In Progress,In Review" --plain 2>/dev/null || echo "None"
echo
echo "Open Bugs:"
jira issue list -l"bug" -s"To Do,In Progress" --plain 2>/dev/null || echo "None"
