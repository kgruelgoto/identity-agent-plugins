# Helper Scripts for Advanced Queries

This directory contains Node.js helper scripts that provide advanced query capabilities beyond what jq offers. These scripts are **optional** and only used when Node.js is available.

## Prerequisites

These scripts require Node.js to be installed. To check:
```bash
node --version
```

If Node.js is not available, fall back to the jq-based queries in `query-examples.md`.

## Available Scripts

### 1. query-by-property.js

**Purpose**: Find SKUs that have a specific property (case-insensitive search).

**Why use this**: Property names in SKU data may vary in casing (e.g., `dialPlanSmsNodeProvisioned` vs `dialplansmsnodeprovisioned`). This script handles case-insensitive matching automatically.

**Usage**:
```bash
node scripts/query-by-property.js <skus-file> <property-name> [output-format]
```

**Output formats**:
- `full` (default): JSON with all details
- `names-only`: Just SKU names, one per line
- `count`: Just the count of matching SKUs

**Examples**:

Find SKUs with dialPlanSmsNodeProvisioned:
```bash
MANIFEST=$(curl -s https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json)
SKU_FILE=$(echo $MANIFEST | jq -r '.skusJs')
curl -s "https://iamdocs.serversdev.getgo.com/fs/live/$SKU_FILE" -o /tmp/skus.js

node scripts/query-by-property.js /tmp/skus.js dialPlanSmsNodeProvisioned
```

Get just the SKU names:
```bash
node scripts/query-by-property.js /tmp/skus.js transcriptsProvisioned names-only
```

Get count only:
```bash
node scripts/query-by-property.js /tmp/skus.js aiReceptionistAllowed count
```

**Output example (full format)**:
```json
{
  "property": "dialPlanSmsNodeProvisioned",
  "found": true,
  "count": 12,
  "skus": [
    {
      "skuName": "CCCompleteL",
      "product": "ccaas",
      "description": "GoTo Contact Complete",
      "propertyPath": "accountEntitlements.jive.dialplansmsnodeprovisioned",
      "propertyValue": true
    },
    ...
  ]
}
```

### 2. find-property-paths.js

**Purpose**: Discover where a property appears in the SKU data structure.

**Why use this**: When you know a property exists but aren't sure where it's located in the nested structure, this script finds all paths.

**Usage**:
```bash
node scripts/find-property-paths.js <skus-file> <property-name>
```

**Example**:

Find all locations of the transcripts property:
```bash
node scripts/find-property-paths.js /tmp/skus.js transcriptsprovisioned
```

**Output example**:
```json
{
  "property": "transcriptsprovisioned",
  "found": true,
  "uniquePaths": 2,
  "totalOccurrences": 145,
  "paths": [
    {
      "path": "licenseEntitlements.g2w.transcriptsprovisioned",
      "actualNames": ["transcriptsprovisioned"],
      "occurrences": 89,
      "exampleValue": true,
      "valueType": "boolean"
    },
    {
      "path": "licenseEntitlements.g2m.transcriptsprovisioned",
      "actualNames": ["transcriptsprovisioned"],
      "occurrences": 56,
      "exampleValue": true,
      "valueType": "boolean"
    }
  ]
}
```

This shows that `transcriptsprovisioned` appears in two places:
- As a G2W license entitlement (89 SKUs)
- As a G2M license entitlement (56 SKUs)

## Using Scripts in Skill Workflow

### Step 1: Check if Node.js is available

```bash
if command -v node >/dev/null 2>&1; then
  echo "Node.js available - using helper scripts"
  USE_NODE=true
else
  echo "Node.js not available - using jq fallback"
  USE_NODE=false
fi
```

### Step 2: Fetch SKU data

```bash
MANIFEST=$(curl -s https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json)
SKU_FILE=$(echo $MANIFEST | jq -r '.skusJs')
curl -s "https://iamdocs.serversdev.getgo.com/fs/live/$SKU_FILE" -o /tmp/skus.js
```

### Step 3: Copy helper scripts to /tmp

```bash
# Get the skill directory path
SKILL_DIR="$(dirname "$(readlink -f "$0")")"

# Copy scripts to /tmp for execution
cp "$SKILL_DIR/scripts/query-by-property.js" /tmp/
cp "$SKILL_DIR/scripts/find-property-paths.js" /tmp/
```

### Step 4: Execute appropriate query

```bash
if [ "$USE_NODE" = true ]; then
  # Use Node.js helper for case-insensitive search
  node /tmp/query-by-property.js /tmp/skus.js "$PROPERTY_NAME"
else
  # Fall back to jq (requires exact property name match)
  cat /tmp/skus.js | sed 's/^skus = //' | jq "[.[] | select(.accountEntitlements.jive.$PROPERTY_NAME != null)]"
fi
```

## When to Use Helper Scripts

Use the helper scripts when:
- ✅ Searching for properties with uncertain casing
- ✅ Need to discover where a property exists in the structure
- ✅ Want to search across all nesting levels
- ✅ Node.js is available in the environment

Use jq when:
- ✅ Node.js is not available
- ✅ You know the exact property path and casing
- ✅ Performing standard filtering/aggregation queries
- ✅ Need maximum compatibility across systems

## Important Notes

1. **Case-insensitive matching**: The scripts convert property names to lowercase for comparison, so `dialPlanSmsNodeProvisioned`, `dialplansmsnodeprovisioned`, and `DIALPLANSMSNODEPROVISIONED` all match.

2. **Deep search**: Scripts search through all nesting levels, not just top-level properties.

3. **Performance**: For large datasets, jq is typically faster. Use helper scripts only when you need their specific capabilities.

4. **Script location**: Scripts should be copied to `/tmp` before execution to avoid path issues.
