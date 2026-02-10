# SKU Query Plugin

Query SKU configurations from the live fulfillment service environment.

## Overview

This plugin enables Claude to fetch and analyze SKU data from the production fulfillment service, answering questions about:
- License attributes and roles
- License entitlements (per-license permissions)
- Account entitlements (account-level settings)
- SKU relationships and dependencies
- Product associations

## Prerequisites

### Required Permission

This plugin requires permission to access the fulfillment service API. Add the following to your project's `.claude/settings.local.json`:

```json
{
  "allowedPrompts": [
    {
      "tool": "Bash",
      "prompt": "curl https://iamdocs.serversdev.getgo.com/*"
    }
  ]
}
```

### Required Tools

- `curl` - for fetching data from the API
- `jq` - for parsing and querying JSON data

Both tools are standard on macOS and most Linux distributions.

## Usage

Once installed, simply ask Claude questions about SKUs:

### Example Questions

**Query by feature:**
```
"Which G2W SKUs give transcription permission?"
"Which SKUs have advancedivrprovisioned as a license entitlement?"
```

**Query by product:**
```
"Which SKUs provide g2c?"
"Show me all jive SKUs with transcription enabled"
```

**Validate SKUs:**
```
"Do these SKUs have license entitlements: G2CCXAU, G2CCXL, CCCompleteU?"
"Does SKU G2CCXU include e911provisioned?"
```

**Compare SKUs:**
```
"What's the difference between G2CCXAL and G2CCXL?"
"Show me all entitlements for SKU G2CCXU"
```

## How It Works

1. **Fetches fresh data** from `https://iamdocs.serversdev.getgo.com/fs/live/` on each query
2. **Parses SKU configurations** including attributes, entitlements, and relationships
3. **Queries the data** using jq based on your question
4. **Presents results** in a structured, readable format

## Data Structure

SKUs contain:
- **License Attributes**: Description, roles, devices allowed, weighted licensing
- **License Entitlements**: Per-license features and permissions
- **Account Entitlements**: Account-level settings and limits
- **Relationships**: Products provided, required, and child SKUs

## Supported Products

- **jive**: Phone system features and settings
- **g2w**: GoTo Webinar features
- **g2m**: GoTo Meeting features
- **g2c**: GoTo Connect features
- **ccaas**: Contact center features
