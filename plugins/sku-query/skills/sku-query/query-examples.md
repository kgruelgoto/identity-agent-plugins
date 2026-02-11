# SKU Query Examples

This file contains common query patterns for different types of SKU questions.

## Query Pattern 1: Find SKUs with Specific Entitlements

**Question**: "Which G2W SKUs give transcription permission?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.product == "g2w" and .licenseEntitlements.g2w.transcriptsprovisioned == true) | {skuName, description: .licenseAttributes.description, transcripts: .licenseEntitlements.g2w.transcriptsprovisioned}'
```

**Pattern**:
- Filter by product: `.product == "product-name"`
- Check license entitlement: `.licenseEntitlements.{product}.{feature} == true`
- Select relevant fields to display

## Query Pattern 2: Find SKUs That Provide a Product

**Question**: "Which SKUs provide g2c?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.provides != null and (.provides | contains(["g2c"]))) | {skuName, description: .licenseAttributes.description, provides}'
```

**Pattern**:
- Check provides array exists: `.provides != null`
- Check array contains value: `(.provides | contains(["value"]))`

## Query Pattern 3: Find SKUs with Specific License Entitlements

**Question**: "Which SKUs have advancedivrprovisioned as a license entitlement?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.licenseEntitlements.jive.advancedivrprovisioned == true) | {skuName, description: .licenseAttributes.description, product}'
```

**Pattern**:
- Direct path to nested entitlement
- Boolean check with `== true`

## Query Pattern 4: Find SKUs with Specific Account Entitlements

**Question**: "Which SKUs enable transcription at account level?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.accountEntitlements.jive.transcriptionallowed == true) | {skuName, description: .licenseAttributes.description, product}'
```

**Pattern**:
- Use `.accountEntitlements.{product}.{setting}` path
- Different from license entitlements path

## Query Pattern 5: Get All Entitlements for a SKU

**Question**: "Show me all entitlements for SKU G2CCXU"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.skuName == "G2CCXU") | {skuName, product, licenseAttributes, licenseEntitlements, accountEntitlements}'
```

**Pattern**:
- Filter by exact SKU name: `.skuName == "NAME"`
- Include all relevant sections

## Query Pattern 6: Validate Multiple SKUs

**Question**: "Do these SKUs have license entitlements: G2CCXAU, G2CCXL, CCCompleteU?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.skuName == "G2CCXAU" or .skuName == "G2CCXL" or .skuName == "CCCompleteU") | {skuName, hasLicenseEntitlements: (.licenseEntitlements != null and .licenseEntitlements != {}), licenseEntitlements, accountEntitlements}'
```

**Pattern**:
- Multiple OR conditions: `.skuName == "A" or .skuName == "B"`
- Computed field: `hasLicenseEntitlements: (expression)`
- Null/empty check: `!= null and != {}`

## Query Pattern 7: Find SKUs by Product

**Question**: "Show me all ccaas SKUs"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.product == "ccaas") | {skuName, description: .licenseAttributes.description}'
```

**Pattern**:
- Simple product filter
- Extract key identifying fields

## Query Pattern 8: Compare License vs Account Entitlements

**Question**: "Which SKUs have transcription as both license AND account entitlement?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.licenseEntitlements.g2w.transcriptsprovisioned == true and .accountEntitlements.g2w.transcriptionallowed == true) | {skuName, product, licenseTranscripts: .licenseEntitlements.g2w.transcriptsprovisioned, accountTranscription: .accountEntitlements.g2w.transcriptionallowed}'
```

**Pattern**:
- Multiple conditions with `and`
- Show both entitlement types in output

## Query Pattern 9: Find SKUs with Requirements

**Question**: "Which SKUs require g2m?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.requires != null and (.requires | contains(["g2m"]))) | {skuName, description: .licenseAttributes.description, requires}'
```

**Pattern**:
- Check requirements array
- Similar to `provides` query

## Query Pattern 10: Find Child SKUs

**Question**: "Which SKUs have child SKUs?"

```bash
cat /tmp/skus-data.js | \
  sed 's/^skus = //' | \
  jq '.[] | select(.childSkus != null and (.childSkus | length > 0)) | {skuName, description: .licenseAttributes.description, childSkus}'
```

**Pattern**:
- Check array not null
- Check array has items: `length > 0`

## Query Pattern 11: Case-Insensitive Property Search (Node.js)

**Question**: "Which SKUs have dialPlanSmsNodeProvisioned?"

**Important**: Property names in SKU data may use different casing. When you're unsure of the exact casing, use the Node.js helper script:

```bash
# First, check if Node.js is available
if command -v node >/dev/null 2>&1; then
  # Copy helper script to /tmp
  cp scripts/query-by-property.js /tmp/

  # Run case-insensitive search
  node /tmp/query-by-property.js /tmp/skus.js dialPlanSmsNodeProvisioned
else
  # Fallback to jq with known exact casing
  cat /tmp/skus.js | sed 's/^skus = //' | \
    jq '.[] | select(.accountEntitlements.jive.dialplansmsnodeprovisioned != null) | {skuName, description: .licenseAttributes.description, value: .accountEntitlements.jive.dialplansmsnodeprovisioned}'
fi
```

**Pattern**:
- Use Node.js helper when property casing is uncertain
- Fall back to jq when Node.js is unavailable
- Helper script searches all nesting levels automatically

**Example Output**:
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
    }
  ]
}
```

## Query Pattern 12: Discover Property Locations (Node.js)

**Question**: "Where does the transcriptsprovisioned property appear in the SKU structure?"

```bash
if command -v node >/dev/null 2>&1; then
  cp scripts/find-property-paths.js /tmp/
  node /tmp/find-property-paths.js /tmp/skus.js transcriptsprovisioned
fi
```

**Use this when**:
- You know a property exists but not its location
- You want to understand all places where a property is used
- You're exploring the data structure

**Example Output**:
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
    }
  ]
}
```

## Adapting Queries

To adapt these patterns:
1. Replace product name: `jive`, `g2w`, `g2m`, `ccaas`, etc.
2. Replace feature name: specific entitlement field
3. Add/remove output fields in the final `{...}` object
4. Combine conditions with `and` or `or`
5. Use Node.js helpers for case-insensitive searches (see `helper-scripts.md`)
