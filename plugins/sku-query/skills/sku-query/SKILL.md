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

**Permission Required**: The skill needs permission to fetch SKU data from the fulfillment service.

This permission must be configured in the project's `.claude/settings.local.json`:
```json
{
  "allowedPrompts": [
    {
      "tool": "Bash",
      "prompt": "fetch SKU data"
    }
  ]
}
```

## Query Process

### Step 1: Fetch SKU Data

Use the provided script to fetch and prepare SKU data:

```
!run bash skills/sku-query/fetch-skus.sh
```

This script:
- Fetches the manifest from `https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json`
- Downloads the current SKU data file
- Saves it to `/tmp/skus-data.js` in the format: `skus = [{...}, {...}, ...]`
- Validates the data was fetched successfully
- Falls back to `skus.js` if the manifest file is unavailable

### Step 2: Determine Query Type

Based on the user's question, load the appropriate reference:

- **For data structure questions** → Read `data-structure.md`
- **For query patterns and examples** → Read `query-examples.md`
- **For formatting output** → Read `output-formats.md`

### Step 3: Execute Query

**Best Practice**: Use jq script files to avoid shell escaping issues with operators like `!=`:

```bash
cat > /tmp/query.jq << 'EOF'
.[] | select(.accountEntitlements.jive.propertyname != null) | {
  skuName,
  description: .licenseAttributes.description
}
EOF

cat /tmp/skus-data.js | sed 's/^skus = //' | sed 's/;$//' | jq -f /tmp/query.jq
```

**Pipeline Components**:
- `cat /tmp/skus-data.js` - Read the fetched data
- `sed 's/^skus = //'` - Strip the JavaScript variable assignment
- `sed 's/;$//'` - Remove trailing semicolon for valid JSON
- `jq -f /tmp/query.jq` - Execute the query from file

### Case Sensitivity in Queries

- **licenseEntitlements and accountEntitlements**: Property names are always lowercase in the data. When querying, normalize the search term using `ascii_downcase`. Example: `.licenseEntitlements.jive | to_entries[] | select(.key == "transcriptsprovisioned")`
- **licenseAttributes**: Property names require exact case matching. Example: `.licenseAttributes.description`

## Error Handling

The fetch script handles errors automatically:
- Reports clear error messages to stderr
- Attempts fallback to `skus.js` if manifest fetch fails
- Validates data format before completing
- Returns non-zero exit code on failure

If fetch fails, check:
1. Network connectivity to iamdocs.serversdev.getgo.com
2. That the allowedPrompts permission is configured
3. The error message from the script for specific details

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
6. **Case handling** - licenseEntitlements and accountEntitlements property names are always lowercase. Normalize search terms with `ascii_downcase`. licenseAttributes require exact case matching.

## Query Tips

### Avoid Shell Escaping Issues
The bash `!` character and `!=` operator can cause escaping problems. **Always use jq script files** (write query to `/tmp/query.jq` then use `jq -f`) instead of inline queries for complex filters.

### Common Patterns
**Check array contains value**:
```jq
select(.provides != null and (.provides | contains(["g2c"])))
```

**Search across product entitlements**:
```jq
.licenseEntitlements | to_entries[] | .value |
if type == "object" then to_entries[] | select(.key == "propertyname") else empty end
```

**Group and count**:
```jq
group_by(.product) | map({product: .[0].product, count: length})
```
