# Jira CLI Skill for Claude Code

Claude Code skill for interacting with Jira using [jira-cli](https://github.com/ankitpokhrel/jira-cli).

## Overview

This skill enables Jira integration within Claude Code for issue management, project tracking, and development workflow automation.

## Features

- Issue creation, viewing, and updating
- Status transitions and assignments
- Smart git-branch to issue linking
- JSON/CSV export for reporting
- Development workflow integration

## Prerequisites

### 1. Install jira-cli

**macOS:**
```bash
brew install ankitpokhrel/jira-cli/jira-cli
```

**Linux:**
```bash
curl -L https://github.com/ankitpokhrel/jira-cli/releases/latest/download/jira-cli_linux_amd64.tar.gz | tar xz
sudo mv jira /usr/local/bin/
```

### 2. Configure Authentication

```bash
jira init
```

Follow the prompts to configure your Jira instance URL and API token.

### 3. Verify Installation

```bash
jira --version
jira me
```

## Quick Start

### Basic Operations

```bash
# List your open issues
jira issue list -a$(jira me) -s"To Do,In Progress" --plain

# Create a task
jira issue create -t"Task" -s"Fix login bug" -yHigh --no-input

# View issue
jira issue view PROJ-123

# Update status
jira issue move PROJ-123 "In Progress"
```

### Using the Helper Scripts

**Git Integration:**
```bash
# Show current issue (from branch name)
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/git-jira-update.sh

# Move to In Progress
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/git-jira-update.sh start

# Move to In Review (when PR is ready)
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/git-jira-update.sh review

# Move to Done (when merged)
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/git-jira-update.sh done
```

**Reports:**
```bash
# Daily standup report
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/daily-standup.sh

# Sprint planning data
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/sprint-planning.sh

# Project statistics
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/issue-stats.sh

# Weekly activity report
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/weekly-report.sh

# Generate dashboard JSON
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/project-dashboard.sh
```

## Skill Structure

```
jira-cli/
├── SKILL.md                      # Main skill instructions for Claude
├── README.md                     # This file - user documentation
├── references/
│   ├── commands.md              # Full command reference
│   └── workflows.md             # Development workflow patterns
└── scripts/
    ├── git-jira-update.sh       # Git integration helper
    ├── daily-standup.sh         # Daily standup report
    ├── sprint-planning.sh       # Sprint planning report
    ├── issue-stats.sh           # Project statistics
    ├── weekly-report.sh         # Weekly activity report
    └── project-dashboard.sh     # Dashboard generator
```

## Usage with Claude

When working in Claude Code, the skill automatically activates when you:
- Mention Jira tickets or issue keys (PROJ-123)
- Request project status or issue tracking
- Work in git repositories with issue references in branches
- Need to create, update, or query issues

Claude will use jira-cli to interact with your Jira instance directly.

## Common Workflows

### Development Workflow

1. Create a feature branch with issue key:
   ```bash
   git checkout -b feature/PROJ-123-user-auth
   ```

2. Update issue status:
   ```bash
   ~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/git-jira-update.sh start
   ```

3. Submit for review after PR:
   ```bash
   ~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/git-jira-update.sh review
   ```

4. Mark complete after merge:
   ```bash
   ~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/git-jira-update.sh done
   ```

### Team Coordination

```bash
# Daily standup prep
jira issue list -a$(jira me) -s"In Progress" --plain

# Check high priority items
jira issue list -y"High,Highest" -s"To Do,In Progress" --plain

# Review completed work
jira issue list -s"Done" --created -7d --plain
```

### Reporting

Use the included report scripts:
```bash
# Daily standup prep
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/daily-standup.sh

# Sprint planning overview
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/sprint-planning.sh

# Project statistics
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/issue-stats.sh

# Weekly activity
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/weekly-report.sh

# Dashboard with metrics
~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/project-dashboard.sh dashboard.json
```

Or export raw data:
```bash
# Export issues for analysis
jira issue list --raw | jq '.issues[] | {
  key: .key,
  status: .fields.status.name,
  priority: .fields.priority.name
}' > issues.json

# Generate CSV report
jira issue list --csv > project_status.csv
```

## Configuration

### Environment Variables

```bash
export JIRA_API_TOKEN="your_token"
export JIRA_AUTH_TYPE="bearer"
export JIRA_SERVER_URL="https://your-domain.atlassian.net"
```

### Shell Aliases

Add to `.bashrc` or `.zshrc`:

```bash
alias jls='jira issue list --plain'
alias jmy='jira issue list -a$(jira me) --plain'
alias jhigh='jira issue list -y"High,Highest" --plain'
```

## Troubleshooting

### Authentication Issues

```bash
# Reset configuration
jira init

# Verify authentication
jira me
```

### Permission Issues

```bash
# Make helper scripts executable
chmod +x ~/.claude/plugins/repos/jira-cli/skills/jira-cli/scripts/*.sh
```

### Missing Dependencies

```bash
# Install jq for JSON processing
brew install jq          # macOS
apt-get install jq       # Ubuntu/Debian
```

## Resources

- [jira-cli GitHub](https://github.com/ankitpokhrel/jira-cli)
- [Jira REST API Documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [JQL Reference](https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/)
