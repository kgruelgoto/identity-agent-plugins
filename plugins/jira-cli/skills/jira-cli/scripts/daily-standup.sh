#!/bin/bash
# Daily standup report generator
# Shows your work in progress, completed yesterday, and blocked items

set -euo pipefail

if ! command -v jira &> /dev/null; then
    echo "Error: jira-cli not installed"
    exit 1
fi

echo "=== My Work ==="
echo
echo "In Progress:"
jira issue list -a$(jira me) -s"In Progress" --plain 2>/dev/null || echo "None"
echo
echo "Completed Yesterday:"
jira issue list -a$(jira me) -s"Done" --created -1d --plain 2>/dev/null || echo "None"
echo
echo "Blocked:"
jira issue list -a$(jira me) -s"Blocked" --plain 2>/dev/null || echo "None"
