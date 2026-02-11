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

## Data Source

The skill fetches data from:
1. `https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json` - to get the current data file name
2. `https://iamdocs.serversdev.getgo.com/fs/live/[manifest-file].js` - the actual SKU data

## Query Process

### Step 1: Fetch SKU Data

```bash
# Get the current manifest
MANIFEST=$(curl -s https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json)
SKU_FILE=$(echo $MANIFEST | jq -r '.skusJs')

# Download the SKU data
curl -s "https://iamdocs.serversdev.getgo.com/fs/live/$SKU_FILE" -o /tmp/skus-data.js
```

The SKU data is a JavaScript file with format: `skus = [{...}, {...}, ...]`

### Step 2: Determine Query Type

Based on the user's question, load the appropriate reference:

- **For data structure questions** → Read `data-structure.md`
- **For query patterns and examples** → Read `query-examples.md`
- **For formatting output** → Read `output-formats.md`

### Step 3: Execute Query

Extract the JSON array and query based on the pattern:

```bash
cat /tmp/skus-data.js | sed 's/^skus = //' | jq '[your query]'
```

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

## Important Notes

1. **Always fetch fresh data** - Don't assume cached data is current
2. **Handle missing fields gracefully** - Not all SKUs have all fields
3. **Check multiple products** - Entitlements can be nested under product keys (jive, g2w, g2m, ccaas, etc.)
4. **Be specific with paths** - Use full JSON paths like `.licenseEntitlements.jive.feature` vs `.accountEntitlements.jive.feature`
5. **Validate SKU names** - Some names are similar (G2CCXU vs G2CCXU-Meeting)
6. **Property names are case-insensitive** - When searching for properties like `dialPlanSmsNodeProvisioned`, the actual casing in the data may vary (e.g., `dialplansmsnodeprovisioned`). Use the Node.js helper scripts for automatic case-insensitive matching, or ensure exact casing when using jq.

## Advanced Queries with Helper Scripts

For case-insensitive property searches and deep path discovery, Node.js helper scripts are available in the `scripts/` directory. See `helper-scripts.md` for details.

**Quick check for Node.js availability**:
```bash
if command -v node >/dev/null 2>&1; then
  # Use helper scripts from scripts/ directory
  node scripts/query-by-property.js /tmp/skus.js propertyName
else
  # Fall back to jq with exact property paths
  cat /tmp/skus.js | sed 's/^skus = //' | jq 'query'
fi
```

Helper scripts provide:
- Case-insensitive property name matching
- Deep property path discovery across all nesting levels
- Multiple output formats (full JSON, names-only, count)

For complete usage examples, refer to `helper-scripts.md`.
