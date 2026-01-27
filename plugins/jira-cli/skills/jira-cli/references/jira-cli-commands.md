# Jira CLI Command Reference

Comprehensive command reference for jira-cli operations. Load this when you need specific command syntax or options.

## Issue Management

### Listing Issues

**Basic listing:**
```bash
jira issue list --plain                    # Human-readable output
jira issue list --raw                      # JSON output
jira issue list --csv                      # CSV output
```

**Filter by status:**
```bash
jira issue list -s"To Do" --plain
jira issue list -s"To Do,In Progress,In Review" --plain
jira issue list -s"Done,Resolved,Closed" --plain
```

**Filter by assignee:**
```bash
jira issue list -a$(jira me) --plain                  # My issues
jira issue list -aUnassigned --plain                  # Unassigned
jira issue list -a"user@example.com" --plain          # Specific user
```

**Filter by priority:**
```bash
jira issue list -y"High,Highest" --plain
jira issue list -y"Low,Lowest" --plain
```

**Filter by labels:**
```bash
jira issue list -l"bug" --plain
jira issue list -l"frontend,urgent" --plain           # Multiple labels (AND)
```

**Filter by time:**
```bash
jira issue list --created -1d --plain                 # Last 24 hours
jira issue list --created -7d --plain                 # Last 7 days
jira issue list --created -30d --plain                # Last 30 days
```

**Combined filters:**
```bash
jira issue list -a$(jira me) -s"In Progress" -y"High" --plain
jira issue list -l"bug" -s"To Do" -y"High,Highest" --plain
```

### Creating Issues

**Non-interactive creation (preferred):**
```bash
jira issue create -t"Bug" -s"Issue summary" -b"Description" --no-input
jira issue create -t"Task" -s"Task title" -yMedium -l"task" --no-input
jira issue create -t"Story" -s"Story title" -b"User story details" --no-input
```

**With priority and labels:**
```bash
jira issue create -t"Bug" -s"Critical bug" -yHighest -l"bug,critical" --no-input
```

**Interactive mode:**
```bash
jira issue create                                     # Opens interactive wizard
```

### Viewing Issues

```bash
jira issue view ISSUE-KEY                             # Full details
jira issue view ISSUE-KEY --comments 5                # With recent comments
jira issue view ISSUE-KEY --plain                     # Plain text format
```

### Editing Issues

```bash
jira issue edit ISSUE-KEY -s"Updated summary" --no-input
jira issue edit ISSUE-KEY -b"Updated description" --no-input
```

### Assigning Issues

```bash
jira issue assign ISSUE-KEY $(jira me)                # Assign to self
jira issue assign ISSUE-KEY "user@example.com"       # Assign to user
jira issue assign ISSUE-KEY "Unassigned"              # Unassign
```

### Status Transitions

```bash
jira issue move ISSUE-KEY                             # Interactive selection
jira issue move ISSUE-KEY "In Progress"               # Direct transition
jira issue move ISSUE-KEY "Done" -RFixed              # With resolution
```

Common transition patterns:
```bash
jira issue move ISSUE-KEY "In Progress"
jira issue move ISSUE-KEY "In Review"
jira issue move ISSUE-KEY "Testing"
jira issue move ISSUE-KEY "Done" -RFixed
```

## Sprint Management

```bash
jira sprint list --plain                              # List all sprints
jira sprint list --current --plain                    # Current sprint
jira sprint list --prev --plain                       # Previous sprint
jira sprint list --next --plain                       # Next sprint
```

## Epic Management

```bash
jira epic list --plain                                # List epics
jira epic create -s"Epic title" -b"Description"       # Create epic
jira epic add EPIC-KEY ISSUE-KEY                      # Add issue to epic
```

## Data Export and Processing

### JSON Processing

```bash
# Extract issue keys
jira issue list --raw | jq -r '.[].key'

# Get specific fields
jira issue list --raw | jq '.[] | {
  key: .key,
  status: .fields.status.name,
  assignee: .fields.assignee.displayName
}'

# Filter by condition
jira issue list --raw | jq '.[] | select(.fields.priority.name == "High")'

# Count by status
jira issue list --raw | jq 'group_by(.fields.status.name) | map({
  status: .[0].fields.status.name,
  count: length
})'
```

### CSV Export

```bash
jira issue list --csv > issues.csv
jira issue list -s"Done" --created -30d --csv > monthly_completed.csv
```

## Utility Commands

```bash
jira me                                               # Get current user info
jira init                                             # Initial configuration
jira --version                                        # Version info
jira --debug issue list                               # Debug mode
```

## Common Query Patterns

### My Work
```bash
jira issue list -a$(jira me) -s"To Do,In Progress" --plain
```

### Team Standup
```bash
jira issue list -s"In Progress" --plain
jira issue list -s"In Review" --plain
jira issue list -s"Done" --created -1d --plain
```

### High Priority Work
```bash
jira issue list -y"High,Highest" -s"To Do,In Progress" --plain
```

### Unassigned Work
```bash
jira issue list -aUnassigned -y"High,Medium" --plain
```

### Bug Tracking
```bash
jira issue list -l"bug" -s"To Do,In Progress" --plain
jira issue list -l"bug" -y"High,Highest" --plain
```

### Sprint Planning
```bash
jira issue list -s"To Do" -y"High,Medium" --plain
jira issue list -s"In Progress,In Review" --plain
```

## Error Handling

Commands may fail if:
- Authentication expired: Run `jira init`
- Invalid status transition: Check workflow configuration
- Missing permissions: Verify Jira permissions
- Invalid issue key: Verify key format (PROJECT-123)

Suppress errors in scripts:
```bash
jira issue move "$ISSUE_KEY" "Done" 2>/dev/null || echo "Transition failed"
```
