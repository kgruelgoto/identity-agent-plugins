#!/bin/bash
# Setup script for jira-cli plugin
# Guides users through installation, configuration, and validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Jira CLI Plugin Setup ===${NC}\n"

# Step 1: Detect Installation Status
echo -e "${BLUE}[1/5] Checking jira-cli installation...${NC}"

if ! command -v jira &> /dev/null; then
    echo -e "${YELLOW}jira-cli is not installed.${NC}\n"

    OS=$(uname -s)
    case "$OS" in
        Darwin)
            echo -e "${YELLOW}Installation command for macOS:${NC}"
            echo "  brew install ankitpokhrel/jira-cli/jira-cli"
            ;;
        Linux)
            echo -e "${YELLOW}Installation commands for Linux:${NC}"
            echo "  curl -L https://github.com/ankitpokhrel/jira-cli/releases/latest/download/jira-cli_linux_amd64.tar.gz | tar xz"
            echo "  sudo mv jira /usr/local/bin/"
            ;;
        *)
            echo -e "${YELLOW}Installation instructions:${NC}"
            echo "  Visit: https://github.com/ankitpokhrel/jira-cli#installation"
            ;;
    esac

    echo ""
    echo -e "${RED}Please install jira-cli and re-run this script.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ jira-cli is installed${NC}\n"

# Step 2: Check Existing Configuration
echo -e "${BLUE}[2/5] Checking existing configuration...${NC}"

CONFIG_FILE="$HOME/.config/.jira/.config.yml"
RECONFIGURE=false

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✓ Existing configuration found${NC}"
    echo ""
    read -p "Do you want to reconfigure jira-cli? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        RECONFIGURE=true
    else
        echo -e "${BLUE}Skipping reconfiguration...${NC}\n"
    fi
else
    echo -e "${YELLOW}No existing configuration found${NC}"
    RECONFIGURE=true
fi

# Step 3: Guide PAT Creation (if configuring)
if [ "$RECONFIGURE" = true ]; then
    echo ""
    echo -e "${BLUE}[3/5] Personal Access Token Setup${NC}"
    echo ""
    echo -e "${YELLOW}To create a Personal Access Token in Jira Server:${NC}"
    echo "  1. Navigate to: https://jira.ops.expertcity.com//secure/ViewProfile.jspa"
    echo "  2. Click 'Personal Access Tokens' in the left menu"
    echo "  3. Click 'Create token'"
    echo "  4. Give it a name (e.g., 'jira-cli')"
    echo "  5. Set appropriate permissions (usually Read/Write for projects)"
    echo "  6. Copy the token immediately (shown only once)"
    echo ""
    read -p "Press Enter when you have your token ready to continue..."
    echo ""

    # Step 4: Run jira init
    echo -e "${BLUE}[4/5] Running jira init...${NC}"
    echo ""
    echo -e "${YELLOW}You'll be prompted for:${NC}"
    echo "  - Installation type: Enter 'local' for Jira Server"
    echo "  - Server URL: Your Jira instance (e.g., https://jira.company.com)"
    echo "  - Login: Your username/email"
    echo "  - Auth type: Enter 'bearer'"
    echo "  - Token: Paste the PAT you just created"
    echo "  - Project: Your default project key"
    echo ""

    if jira init; then
        echo ""
        echo -e "${GREEN}✓ Configuration completed${NC}\n"
    else
        echo ""
        echo -e "${RED}✗ Configuration failed${NC}"
        echo "Please try running 'jira init' manually or check your inputs."
        exit 1
    fi
else
    echo -e "${BLUE}[3/5] Skipped - using existing configuration${NC}"
    echo -e "${BLUE}[4/5] Skipped - using existing configuration${NC}"
    echo ""
fi

# Step 5: Validate Configuration
echo -e "${BLUE}[5/5] Validating configuration...${NC}"

if jira me &> /dev/null; then
    USERNAME=$(jira me 2>/dev/null || echo "user")
    echo -e "${GREEN}✓ Authentication successful!${NC}"
    echo -e "${GREEN}✓ Logged in as: ${USERNAME}${NC}\n"

    echo -e "${GREEN}=== Setup Complete ===${NC}\n"
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  - Try: jira issue list --plain"
    echo "  - View your profile: jira me"
    echo "  - Create an issue: jira issue create"
    echo ""
    echo "For more information, see the README:"
    echo "  ~/.claude/plugins/repos/jira-cli/README.md"
    echo ""
else
    echo -e "${RED}✗ Authentication failed${NC}"
    echo ""
    echo "The configuration exists but authentication is not working."
    echo "This could be due to:"
    echo "  - Invalid or expired token"
    echo "  - Incorrect server URL"
    echo "  - Network connectivity issues"
    echo ""
    echo "To reconfigure, run:"
    echo "  jira init --force"
    echo ""
    exit 1
fi
