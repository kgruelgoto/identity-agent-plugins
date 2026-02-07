---
name: jira-cli
description: Interact with Jira using the jira-cli tool for issue management, sprints, epics, and workflows. Use when working with Jira tickets, project management, or when users mention Jira operations. Requires jira-cli to be installed and configured.
allowed-tools: Bash, Read, Write, Grep, Glob
---

# Jira CLI Integration

Use jira-cli for Jira operations when users mention tickets, issues, or project management tasks.

## Prerequisites Check

Before any Jira operations, verify tool availability:
```bash
# Check if jira-cli exists and is configured
if ! command -v jira &> /dev/null; then
    echo "jira-cli not installed. Run setup script:"
    echo "~/.claude/plugins/repos/jira-cli/scripts/setup.sh"
    exit 1
fi

# Verify authentication
if ! jira me &> /dev/null; then
    echo "jira-cli not configured. Run setup script:"
    echo "~/.claude/plugins/repos/jira-cli/scripts/setup.sh"
    exit 1
fi
```

## Core Operations

### List and Query Issues
```bash
# Basic listing with filters
jira issue list --plain                                    # Human-readable
jira issue list --raw                                      # JSON for processing
jira issue list -s"To Do,In Progress" -a$(jira me) --plain
jira issue list -y"High,Highest" -l"bug" --plain
jira issue list --created -7d --raw
```

### Create Issues
```bash
# Non-interactive creation (preferred for automation)
jira issue create -t"Bug" -s"Summary here" -b"Description" -yHigh -l"bug" --no-input
```

See [references/issue-creation-guide.md](references/issue-creation-guide.md) for comprehensive guidance on writing effective summaries and descriptions.

### View and Update Issues
```bash
jira issue view ISSUE-KEY --comments 5
jira issue assign ISSUE-KEY $(jira me)
jira issue move ISSUE-KEY "In Progress"
jira issue move ISSUE-KEY "Done" -RFixed
```

## Output Processing

- Use `--plain` for displaying to users
- Use `--raw` for programmatic processing with jq
- Use `--csv` for data export

```bash
# Extract data with jq (note: jira-cli returns array directly, not wrapped)
jira issue list --raw | jq -r '.[].key'
jira issue list --raw | jq '.[] | {key: .key, status: .fields.status.name}'
```

## When to Use This Skill

Trigger when users:
- Mention Jira tickets, issues, or issue keys (PROJ-123)
- Request project status or issue tracking
- Want to create, update, or query issues
- Work in git context with issue references in branches/commits
- Need sprint or epic management
- Ask to create bug reports or break down specifications

## Integration Patterns

### Git Context Integration
Extract issue keys from branch names or commits:
```bash
BRANCH=$(git branch --show-current)
ISSUE_KEY=$(echo "$BRANCH" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)

# Update issue based on development state
[ -n "$ISSUE_KEY" ] && jira issue move "$ISSUE_KEY" "In Progress"
```

### Batch Operations
Process multiple issues programmatically:
```bash
jira issue list -aUnassigned -y"High" --raw | jq -r '.[].key' | while read key; do
    jira issue assign "$key" $(jira me)
done
```

## Issue Creation Guidance

When users request help creating Jira tickets:

**For Bug Reports**: Reference [references/bug-report-templates.md](references/bug-report-templates.md) for templates covering:
- Backend errors with stack traces
- Frontend/UI issues with reproduction steps
- Performance problems with metrics
- Data integrity issues
- Integration failures
- Regressions of previously fixed issues

**For Features/Tasks**: Use [references/issue-creation-guide.md](references/issue-creation-guide.md) which includes:
- Summary writing formulas and best practices
- Description templates by task type
- Acceptance criteria guidelines
- Examples for backend, frontend, infrastructure, and documentation tasks

**For Breaking Down Work**: Reference [references/task-breakdown-examples.md](references/task-breakdown-examples.md) for examples of:
- Feature development breakdown (new features into implementable tasks)
- Infrastructure project breakdown (migrations, deployments)
- API development breakdown
- Frontend redesign breakdown
- Anti-patterns to avoid

## Reporting Scripts

Convenience scripts are available in `scripts/` for common reporting tasks:

```bash
# Daily standup report
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/daily-standup.sh

# Sprint planning overview
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/sprint-planning.sh

# Project statistics
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/issue-stats.sh

# Weekly activity report
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/weekly-report.sh

# JSON dashboard generator
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/project-dashboard.sh [output.json]

# Git context issue updater
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/git-jira-update.sh [start|review|done|info]
```

Use these scripts instead of building equivalent jq queries when users request reports or summaries.

## Best Practices

1. **Use non-interactive mode** (`--no-input`) for automation
2. **Handle errors gracefully** - commands may fail if workflow states don't match
3. **Extract issue keys** from git branches when in development context
4. **Batch similar operations** rather than one-off commands when processing multiple issues
5. **Use JSON output** for any data processing or analysis
6. **Use provided scripts** for common reports rather than inline jq processing
7. **Reference issue creation guides** when helping users write tickets
8. **Follow ticket writing best practices** from references when creating issues

## Additional Resources

For detailed command syntax and examples:
- [references/jira-cli-commands.md](references/jira-cli-commands.md) - Complete command reference with all options and filters

For development workflow integration:
- [references/development-workflow-patterns.md](references/development-workflow-patterns.md) - Git integration, CI/CD patterns, batch operations
