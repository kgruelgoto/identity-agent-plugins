# Development Workflow Patterns

Practical patterns for integrating jira-cli into development workflows.

## Git Integration Patterns

### Extract Issue Key from Git Context

```bash
# From current branch
BRANCH=$(git branch --show-current)
ISSUE_KEY=$(echo "$BRANCH" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)

# From recent commits
COMMIT_MSG=$(git log -1 --format=%B)
ISSUE_KEY=$(echo "$COMMIT_MSG" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)

# From commit range
COMMITS=$(git log origin/main..HEAD --format=%B)
ISSUE_KEY=$(echo "$COMMITS" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)
```

### Automatic Status Updates

**When starting work on a branch:**
```bash
ISSUE_KEY=$(git branch --show-current | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)
if [ -n "$ISSUE_KEY" ]; then
    jira issue move "$ISSUE_KEY" "In Progress" 2>/dev/null
    jira issue assign "$ISSUE_KEY" $(jira me) 2>/dev/null
fi
```

**When creating a PR:**
```bash
ISSUE_KEY=$(git branch --show-current | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)
if [ -n "$ISSUE_KEY" ]; then
    jira issue move "$ISSUE_KEY" "In Review" 2>/dev/null
fi
```

**When merging to main:**
```bash
ISSUE_KEY=$(git log -1 --format=%B | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)
if [ -n "$ISSUE_KEY" ]; then
    jira issue move "$ISSUE_KEY" "Done" 2>/dev/null
fi
```

## Development Workflows

### Feature Development

```bash
# 1. Create feature issue
ISSUE_KEY=$(jira issue create -t"Story" \
    -s"Implement user authentication" \
    -b"Add login flow with OAuth" \
    --no-input | grep -oE '[A-Z][A-Z0-9]+-[0-9]+')

# 2. Create branch
git checkout -b feature/${ISSUE_KEY}-user-auth

# 3. Start work
jira issue move "$ISSUE_KEY" "In Progress"
jira issue assign "$ISSUE_KEY" $(jira me)

# 4. Submit for review (after PR creation)
jira issue move "$ISSUE_KEY" "In Review"

# 5. Complete (after merge)
jira issue move "$ISSUE_KEY" "Done" -RFixed
```

### Bug Triage and Fix

```bash
# 1. Create bug report
ISSUE_KEY=$(jira issue create -t"Bug" \
    -s"Login fails with special characters" \
    -yHigh -l"bug,security" \
    -b"Users cannot login when email contains + character" \
    --no-input | grep -oE '[A-Z][A-Z0-9]+-[0-9]+')

# 2. Create fix branch
git checkout -b bugfix/${ISSUE_KEY}-login-validation

# 3. Track work
jira issue move "$ISSUE_KEY" "In Progress"

# 4. Complete
jira issue move "$ISSUE_KEY" "Done" -RFixed
```

## Reporting and Analytics

Use the provided scripts for common reports:

### Daily Standup Report
```bash
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/daily-standup.sh
```
Shows your in-progress work, yesterday's completions, and blocked items.

### Sprint Planning Report
```bash
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/sprint-planning.sh
```
Shows backlog items, in-progress work, and open bugs.

### Issue Statistics
```bash
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/issue-stats.sh
```
Displays project-wide metrics and status distribution.

### Weekly Report
```bash
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/weekly-report.sh
```
Shows issues created and completed this week.

### Project Dashboard
```bash
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/project-dashboard.sh [output.json]
```
Generates JSON dashboard with key metrics.

## Batch Operations

### Assign Multiple Issues

```bash
# Assign unassigned high-priority issues to self
jira issue list -aUnassigned -y"High" --raw | jq -r '.[].key' | while read key; do
    jira issue assign "$key" $(jira me)
    echo "Assigned $key"
done
```

### Bulk Status Update

```bash
# Move all issues in review to testing (after deploy)
jira issue list -s"In Review" --raw | jq -r '.[].key' | while read key; do
    jira issue move "$key" "Testing" 2>/dev/null && echo "Moved $key to Testing"
done
```

## CI/CD Integration

### Deployment Pipeline

```bash
# In your CI/CD script
ISSUE_KEY=$(git log -1 --format=%B | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)

if [ -n "$ISSUE_KEY" ]; then
    case "$CI_ENVIRONMENT" in
        staging)
            jira issue move "$ISSUE_KEY" "Testing" 2>/dev/null
            ;;
        production)
            jira issue move "$ISSUE_KEY" "Done" 2>/dev/null
            ;;
    esac
fi
```

### Post-Deploy Verification

```bash
# Get issues deployed in this release
git log $PREVIOUS_TAG..HEAD --format=%B | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | sort -u | while read key; do
    echo "Deployed: $key - $(jira issue view $key --plain | head -5)"
done
```

## Decision Points for Agents

When integrating Jira operations:

1. **Always check git context first** - Extract issue keys from branch/commit before asking user
2. **Use non-interactive mode** - Never use interactive commands in automation
3. **Handle transition failures gracefully** - Status transitions depend on workflow configuration
4. **Batch operations when possible** - Process multiple issues in one loop rather than serial calls
5. **Use provided scripts** - Reference scripts in `scripts/` directory for common reports
6. **Extract structured data** - Use `--raw` with jq for any data processing
7. **Suppress expected errors** - Use `2>/dev/null || true` when transitions might fail

## Common Patterns

### Check if in git repo with Jira issue reference
```bash
if git rev-parse --git-dir > /dev/null 2>&1; then
    ISSUE_KEY=$(git branch --show-current | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)
    [ -n "$ISSUE_KEY" ] && echo "Working on: $ISSUE_KEY"
fi
```

### Safe status transition
```bash
if jira issue view "$ISSUE_KEY" > /dev/null 2>&1; then
    jira issue move "$ISSUE_KEY" "In Progress" 2>/dev/null || \
        echo "Issue $ISSUE_KEY already in progress or transition not available"
fi
```

### Generate custom report
```bash
# Use scripts as templates for custom reports
# See scripts/issue-stats.sh and scripts/project-dashboard.sh
jira issue list -s"To Do,In Progress" --raw | jq '{
    total: length,
    by_assignee: (group_by(.fields.assignee.displayName // "Unassigned") | map({
        assignee: (.[0].fields.assignee.displayName // "Unassigned"),
        count: length
    }))
}'
```
