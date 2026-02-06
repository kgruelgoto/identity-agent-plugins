---
name: sku-query
description: Query SKU configurations from the live fulfillment service environment to answer questions about license attributes, entitlements, SKU relationships, and product associations. Use when users ask about SKU features, permissions, or validations.
allowed-tools: Bash, Read, Write, Grep, Glob
---

# Query SKUs Skill

Query SKU configurations from the live fulfillment service environment.

## What This Skill Does

This skill fetches and queries SKU data from https://iamdocs.serversdev.getgo.com/fs/live/skus.html to answer questions about:
- License attributes (roles, descriptions, features)
- License entitlements (per-license permissions and features)
- Account entitlements (account-level permissions and settings)
- SKU relationships (provides, requires, childSkus)
- Product associations

## Prerequisites

**Permission Required**: The skill needs permission to run `curl https://iamdocs.serversdev.getgo.com/*`

This permission must be configured in the project's `.claude/settings.local.json`:
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

## How to Use This Skill

When the user asks questions about SKUs, use this skill to:

1. **Fetch current SKU data** from the live environment
2. **Query specific attributes** based on the user's question
3. **Present results** in a clear, actionable format

## Data Source and Structure

The skill fetches data from:
1. `https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json` - to get the current data file name
2. `https://iamdocs.serversdev.getgo.com/fs/live/[manifest-file].js` - the actual SKU data

Each SKU has this structure:
```json
{
  "skuName": "G2CCXU",
  "product": "jive",
  "isUnlimitedSku": true,
  "childSkus": ["..."],
  "licenseAttributes": {
    "description": "...",
    "roles": ["ROLE_..."],
    "devicesAllowed": true,
    "weighted": true,
    ...
  },
  "licenseEntitlements": {
    "product": {
      "featurename": value,
      ...
    }
  },
  "accountEntitlements": {
    "product": {
      "settingname": value,
      ...
    }
  },
  "provides": ["..."],
  "requires": ["..."],
  "requiresAny": [["..."]],
  ...
}
```

## Query Process

### Step 1: Fetch SKU Data

```bash
# Get the current manifest
MANIFEST=$(curl -s https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json)
SKU_FILE=$(echo $MANIFEST | jq -r '.skusJs')

# Download the SKU data
curl -s "https://iamdocs.serversdev.getgo.com/fs/live/$SKU_FILE" -o /tmp/skus-data.js
```

### Step 2: Parse and Query

The SKU data is a JavaScript file with format: `skus = [{...}, {...}, ...]`

Extract the JSON array and query it based on the user's question.

## Example Queries

### Query 1: Find SKUs with specific entitlements
**Question**: "Which G2W SKUs give transcription permission?"

```bash
# Extract SKUs and filter
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.product == "g2w" and .licenseEntitlements.g2w.transcriptsprovisioned == true) | {skuName, description: .licenseAttributes.description, transcripts: .licenseEntitlements.g2w.transcriptsprovisioned}'
```

### Query 2: Find SKUs that provide a product
**Question**: "Which SKUs provide g2c?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.provides != null and (.provides | contains(["g2c"]))) | {skuName, description: .licenseAttributes.description, provides}'
```

### Query 3: Find SKUs with specific license entitlements
**Question**: "Which SKUs have advancedivrprovisioned as a license entitlement?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.licenseEntitlements.jive.advancedivrprovisioned == true) | {skuName, description: .licenseAttributes.description, product}'
```

### Query 4: Find SKUs with specific account entitlements
**Question**: "Which SKUs enable transcription at account level?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.accountEntitlements.jive.transcriptionallowed == true) | {skuName, description: .licenseAttributes.description, product}'
```

### Query 5: Compare license vs account entitlements
**Question**: "Show me all entitlements for SKU G2CCXU"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.skuName == "G2CCXU") | {skuName, product, licenseAttributes, licenseEntitlements, accountEntitlements}'
```

### Query 6: Validate SKU changes
**Question**: "Do these SKUs have license entitlements: G2CCXAU, G2CCXL, CCCompleteU?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.skuName == "G2CCXAU" or .skuName == "G2CCXL" or .skuName == "CCCompleteU") | {skuName, hasLicenseEntitlements: (.licenseEntitlements != null and .licenseEntitlements != {}), licenseEntitlements, accountEntitlements}'
```

## Output Format

Structure your responses based on the query type:

### For feature/permission queries:
```markdown
## SKUs with [feature/permission]

**Found N SKUs:**

1. **[SKU-NAME]** - [Description]
   - Product: [product]
   - [Relevant entitlement details]

2. **[SKU-NAME]** - [Description]
   ...
```

### For validation queries:
```markdown
## SKU Validation Results

**SKU: [NAME]**
- Product: [product]
- License Entitlements: [present/absent]
  - [list if present]
- Account Entitlements: [present/absent]
  - [list if present]

**Analysis**: [What this means for the change being validated]
```

### For comparison queries:
```markdown
## SKU Comparison

| SKU | Product | License Entitlements | Account Entitlements |
|-----|---------|---------------------|---------------------|
| ... | ...     | ...                 | ...                 |

**Key Differences**: [highlight important distinctions]
```

## Important Notes

1. **Always fetch fresh data** - Don't assume cached data is current
2. **Handle missing fields gracefully** - Not all SKUs have all fields
3. **Check multiple products** - Entitlements can be nested under product keys (jive, g2w, g2m, ccaas, etc.)
4. **Be specific with paths** - Use full JSON paths like `.licenseEntitlements.jive.feature` vs `.accountEntitlements.jive.feature`
5. **Validate SKU names** - Some names are similar (G2CCXU vs G2CCXU-Meeting)

## Common Fields to Query

### License Attributes
- `description`: Human-readable SKU name
- `roles`: Array of roles granted
- `devicesAllowed`: Whether devices are allowed
- `weighted`: Whether SKU uses weighted licensing
- `maxAttendees`: Max meeting attendees

### License Entitlements (per-license)
Common fields by product:
- **jive**: `advancedivrprovisioned`, `e911provisioned`, etc.
- **g2w**: `transcriptsprovisioned`, `recordingsprovisioned`, etc.
- **g2m**: `transcriptsprovisioned`, `summaryprovisioned`, `breakoutsprovisioned`, etc.
- **ccaas**: Various contact center features

### Account Entitlements (account-level)
Common fields by product:
- **jive**: `transcriptionallowed`, `maxcallqueues`, `maxdids`, `advancedreportingallowed`, etc.
- **g2w**: Various webinar settings
- **ccaas**: `aicallanalysis`, `sku`, etc.

### Relationships
- `provides`: Array of products/features this SKU provides
- `requires`: Array of products required
- `requiresAny`: Array of arrays for "one of these" requirements
- `childSkus`: Array of child SKU names

## Error Handling

If the data fetch fails:
1. Check network connectivity
2. Verify the manifest endpoint is accessible
3. Try the fallback: `https://iamdocs.serversdev.getgo.com/fs/live/skus.js`
4. Report the error clearly to the user

## When to Use This Skill

Use this skill when the user asks about:
- "Which SKUs have [feature]?"
- "Does SKU [name] include [permission]?"
- "Show me all [product] SKUs with [entitlement]"
- "What's the difference between [SKU1] and [SKU2]?"
- "Validate that SKU [name] has [property]"
- "Which SKUs provide [product]?"
- "What entitlements does [SKU] grant?"
