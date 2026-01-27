#!/bin/bash
# Minimal example: Update Jira issue based on git context
# Usage: git-jira-update.sh [start|review|done]

set -euo pipefail

# Extract issue key from current branch or recent commit
extract_issue_key() {
    local branch=$(git branch --show-current 2>/dev/null || echo "")
    local issue_key=$(echo "$branch" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1 || echo "")

    if [ -z "$issue_key" ]; then
        issue_key=$(git log -1 --format=%B | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1 || echo "")
    fi

    echo "$issue_key"
}

# Check prerequisites
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

if ! command -v jira &> /dev/null; then
    echo "Error: jira-cli not installed"
    exit 1
fi

# Get issue key
ISSUE_KEY=$(extract_issue_key)
if [ -z "$ISSUE_KEY" ]; then
    echo "Error: No issue key found in branch name or recent commit"
    echo "Branch names should include: feature/PROJ-123-description"
    exit 1
fi

echo "Found issue: $ISSUE_KEY"

# Determine action
ACTION=${1:-info}

case "$ACTION" in
    start)
        echo "Moving $ISSUE_KEY to In Progress..."
        jira issue move "$ISSUE_KEY" "In Progress" 2>/dev/null && \
            echo "✓ Moved to In Progress" || \
            echo "⚠ Could not move (may already be in progress)"
        jira issue assign "$ISSUE_KEY" $(jira me) 2>/dev/null
        ;;
    review)
        echo "Moving $ISSUE_KEY to In Review..."
        jira issue move "$ISSUE_KEY" "In Review" 2>/dev/null && \
            echo "✓ Moved to In Review" || \
            echo "⚠ Could not move to In Review"
        ;;
    done)
        echo "Moving $ISSUE_KEY to Done..."
        jira issue move "$ISSUE_KEY" "Done" 2>/dev/null && \
            echo "✓ Moved to Done" || \
            echo "⚠ Could not move to Done"
        ;;
    info)
        jira issue view "$ISSUE_KEY" --plain
        ;;
    *)
        echo "Usage: $0 [start|review|done|info]"
        echo "  start  - Move issue to In Progress"
        echo "  review - Move issue to In Review"
        echo "  done   - Move issue to Done"
        echo "  info   - Show issue details (default)"
        exit 1
        ;;
esac
