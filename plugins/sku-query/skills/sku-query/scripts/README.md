# SKU Query Helper Scripts

This directory contains Node.js utility scripts for advanced SKU querying capabilities.

## Scripts

- **query-by-property.js** - Case-insensitive property search across all SKUs
- **find-property-paths.js** - Discover all locations where a property exists

## Purpose

These scripts complement the jq-based queries by providing:

1. **Case-insensitive property matching** - Property names may vary in casing across the SKU data
2. **Deep nested search** - Automatically searches through all nesting levels
3. **Path discovery** - Shows exactly where properties are located in the data structure

## Usage

See `../helper-scripts.md` for complete documentation and examples.

## Quick Example

```bash
# Fetch SKU data
MANIFEST=$(curl -s https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json)
SKU_FILE=$(echo $MANIFEST | jq -r '.skusJs')
curl -s "https://iamdocs.serversdev.getgo.com/fs/live/$SKU_FILE" -o /tmp/skus.js

# Find SKUs with a property (case-insensitive)
node query-by-property.js /tmp/skus.js dialPlanSmsNodeProvisioned

# Discover where a property exists
node find-property-paths.js /tmp/skus.js transcriptsprovisioned
```

## When to Use

Use these scripts when:
- You're unsure of the exact property name casing
- You need to discover where a property exists in the structure
- You're searching across multiple nesting levels
- Node.js is available in your environment

Use jq when:
- Node.js is not available
- You know the exact property path
- You need maximum performance and compatibility
