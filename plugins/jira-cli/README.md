# Jira CLI Plugin for Claude Code

Claude Code plugin for interacting with Jira using [jira-cli](https://github.com/ankitpokhrel/jira-cli).

## Overview

This plugin enables Jira integration within Claude Code for issue management, project tracking, and development workflow automation.

## Installation

### Quick Setup

Run the automated setup script:
```bash
# Standard installation path
~/.claude/plugins/repos/jira-cli/scripts/setup.sh

# Or use the plugin root variable (works in any installation)
${CLAUDE_PLUGIN_ROOT}/jira-cli/scripts/setup.sh
```

This script will:
- Check if jira-cli is installed (and guide installation if needed)
- Walk you through creating a Personal Access Token
- Configure jira-cli with your Jira Server instance
- Validate the configuration

### Manual Setup

If you prefer manual setup:

1. **Install jira-cli:**
   ```bash
   # macOS
   brew install ankitpokhrel/jira-cli/jira-cli

   # Linux
   curl -L https://github.com/ankitpokhrel/jira-cli/releases/latest/download/jira-cli_linux_amd64.tar.gz | tar xz
   sudo mv jira /usr/local/bin/
   ```

2. **Create Personal Access Token:**
   - Navigate to your Jira profile: `https://YOUR-JIRA-SERVER/secure/ViewProfile.jspa`
   - Click "Personal Access Tokens"
   - Create a new token with appropriate permissions
   - Copy the token (shown only once)

3. **Configure jira-cli:**
   ```bash
   jira init
   ```

   When prompted:
   - Installation type: `local`
   - Server URL: Your Jira instance (e.g., `https://jira.company.com`)
   - Login: Your username/email
   - Auth type: `bearer`
   - Token: Paste your PAT
   - Project: Your default project key

4. **Verify:**
   ```bash
   jira me
   ```

### Install Plugin

`claude plugin install kgruelgoto/jira-cli`

The skill will automatically activate when you mention Jira tickets, issues, or project
management tasks in Claude Code.

### Verify Installation

# List installed plugins
`claude plugin list`

The skill should appear when relevant - test it - in Claude Code, ask: "Show me my open Jira issues"


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

## Plugin Structure

```
jira-cli/
├── .claude-plugin/
│   └── plugin.json               # Plugin metadata
├── README.md                     # This file - user documentation
└── skills/
    └── jira-cli/
        ├── SKILL.md              # Main skill instructions for Claude
        ├── README.md             # Skill documentation
        ├── references/           # Progressive disclosure references
        │   ├── bug-report-templates.md
        │   ├── development-workflow-patterns.md
        │   ├── issue-creation-guide.md
        │   ├── jira-cli-commands.md
        │   └── task-breakdown-examples.md
        └── scripts/              # Helper scripts
            ├── git-jira-update.sh
            ├── daily-standup.sh
            ├── sprint-planning.sh
            ├── issue-stats.sh
            ├── weekly-report.sh
            └── project-dashboard.sh
```

## Usage with Claude

When working in Claude Code with this plugin installed, the skill automatically activates when you:
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
