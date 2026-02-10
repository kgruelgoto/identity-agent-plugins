# Jira Ticket Parsing Patterns

This guide documents common patterns found in Jira ticket descriptions for automated extraction of requirements.

## Fetching Jira Tickets

Use jira-cli to fetch ticket details:
```bash
jira issue view IAMTASKS-1999 --plain
```

## SKU Name Extraction

### Pattern 1: Bold Labels
```
**License Name:** GoToConnect Internal Dial Only Handset
**OFS Template Name (BOSS):** G2CInternalOnlyL
**OFS Template Name (JIVE):** G2CInternalOnlyU
```
Extract: `["G2CInternalOnlyL", "G2CInternalOnlyU"]`

### Pattern 2: List Format
```
New SKUs:
- ResolveStarter
- ResolveAdvanced
- ResolvePremium
```
Extract: `["ResolveStarter", "ResolveAdvanced", "ResolvePremium"]`

### Pattern 3: Inline Text
```
Create SKUs: G2CPremiumL, G2CPremiumU, G2CTrial
```
Extract: Comma-separated list

## Product Identification

Look for product names or prefixes:
- `G2C*` → product: "g2c" (GoToConnect)
- `GTR*` or `Resolve*` → product: "gotoresolve"
- `G2M*` or `Meeting*` → product: "g2m" (GoToMeeting)
- `Jive*` → product: "jive"

## Template References

### Pattern 1: "Copy of" or "Based on"
```
Copy settings from G2CLowUsage template
```
Extract base template: `G2CLowUsage`

### Pattern 2: "Similar to"
```
Should be similar to existing G2CStandard SKU
```
Extract base template: `G2CStandard`

## Entitlement Extraction

### Pattern 1: New Attribute
```
Add a new license attribute called blockpstn (boolean)
Default value: false
```
Extract:
- Attribute name: `blockpstn`
- Type: boolean
- Default: `false`

### Pattern 2: Entitlement List
```
License entitlements:
- maxattendees: 250
- isrecordmeetingsprovisioned: true
- isdialoutprovisioned: true
```
Extract as Map:
```java
Map.of(
    "maxattendees", 250,
    "isrecordmeetingsprovisioned", true,
    "isdialoutprovisioned", true
)
```

### Pattern 3: Account-level Entitlements
```
Account entitlements:
- breakoutsentitled: true
- gotoappenabled: true
```
Extract as account entitlements (not license entitlements)

## SKU Type Detection

### Add-on SKU
Keywords: "add-on", "addon", "child SKU", "requires base license"
→ `withIsAddonSku(true)`

### Standalone SKU
Keywords: "standalone", "base license", "primary SKU"
→ `withIsAddonSku(false)`

### Child SKU
Keywords: "child SKU of", "attached to", "sub-license"
→ `withIsChildSku(true)`

## Role Detection

### Pattern 1: Explicit Role Names
```
Roles: ROLE_GOTOCONNECT_ORGANIZER, ROLE_JIVE_USER
```
Extract as Set: `Set.of("ROLE_GOTOCONNECT_ORGANIZER", "ROLE_JIVE_USER")`

### Pattern 2: Product-based Inference
- GoToConnect → `ROLE_GOTOCONNECT_ORGANIZER`, `ROLE_JIVE_USER`
- GoTo Resolve → `ROLE_GOTORESOLVE_ORGANIZER`
- With "mobile" → add `ROLE_GOTORESOLVE_MOBILE_ORGANIZER`
- GoToMeeting → `ROLE_G2M_ORGANIZER`

## Operation Type Detection

### SKU Creation
Keywords:
- "Create new SKU"
- "New OFS Template"
- "Add SKU"
- "Define new license"

Action: Use `CreateOrUpdateSkuStage`

### SKU Update Only
Keywords:
- "Update SKU definition"
- "Modify SKU"
- "Change SKU settings"
- No mention of existing licenses

Action: Use `CreateOrUpdateSkuStage` + `RunOnCloseStage` only

### SKU Update + License Sweep
Keywords:
- "Update existing licenses"
- "Apply to all accounts"
- "Sweep licenses"
- "Update licenses with SKU"
- "Scan and update"

Action: Use full pipeline with `ScanLicensesByAttrStage` + `UpdateLicenseEntsStage`

### Role Update Only
Keywords:
- "Add role to SKU"
- "Update roles"
- "Change license roles"

Action: Use `UpdateSkuStage` (simpler pattern)

## Example: IAMTASKS-1999

**Ticket Description:**
```
Create new SKU for GoToConnect Internal Dial Only Handset

**License Name:** GoToConnect Internal Dial Only Handset
**OFS Template Name (BOSS):** G2CInternalOnlyL
**OFS Template Name (JIVE):** G2CInternalOnlyU

This should be a copy of the G2CLowUsage template with an additional license
attribute called blockpstn (boolean, default false).

This is an add-on license type.

Update all existing G2CLowUsage licenses to include the new blockpstn attribute.
```

**Extracted Requirements:**
```java
// SKU Names
var skuNames = List.of("G2CInternalOnlyL", "G2CInternalOnlyU");

// Product
var product = "g2c";

// Base Template
var baseTemplate = "G2CLowUsage";

// Operation Type
// - SKU Creation (new SKUs)
// - License Sweep ("Update all existing... licenses")

// New Attribute
var newAttribute = Map.of("blockpstn", false);

// SKU Type
// - Add-on (explicitly stated)

// Roles (inferred from G2C)
var roles = Set.of("ROLE_JIVE_USER");

// Pipeline Needed
// CreateOrUpdateSkuStage → InjectOnCloseStage → PartitionStage →
// ScanLicensesByAttrStage → UpdateLicenseEntsStage → RunOnCloseStage
```

## Common Patterns Summary

| Pattern | Indicator | Action |
|---------|-----------|--------|
| New SKU | "Create new", "new OFS Template" | CreateOrUpdateSkuStage |
| License Sweep | "update existing", "apply to accounts" | Add license scan stages |
| Role Update | "add role", "update roles" | UpdateSkuStage |
| Copy Template | "copy of", "based on" | Fetch base SKU entitlements |
| Add-on | "add-on", "addon" | withIsAddonSku(true) |
| Child SKU | "child SKU" | withIsChildSku(true) |

## Attribute Name Normalization

Jira descriptions may use various formats. Normalize to standard attribute names:
- "block PSTN" → `blockpstn`
- "max attendees" → `maxattendees`
- "is dial out provisioned" → `isdialoutprovisioned`

Rules:
1. Remove spaces
2. Convert to lowercase
3. Remove special characters
4. Keep as camelCase

## Critical Validation Rules

### FALSE Value Anti-Pattern (CRITICAL)

**Problem**: Tickets sometimes request adding attributes with `false` values.

**Why This is Wrong**:
- False values are stop conditions - they don't enable capabilities
- Adding "feature: false" to a new SKU means the feature is disabled
- This is typically a misunderstanding of how entitlements work

**Examples of Problematic Requests**:
```
❌ "Add blockpstn attribute with default value false"
❌ "Set maxattendees to false"
❌ "New attribute: canstarttrial = false"
```

**When to Question**:
- Any new attribute with `false` boolean value
- Any numeric attribute set to 0 or empty string
- Attributes that appear to disable features on a new SKU

**Exceptions** (when false is valid):
- Negative capability flags where false = enabled (e.g., "blockfeature" where false means don't block)
- Explicitly documented stop conditions
- Copying from base template where false is the inherited value

**What to Do**:
1. Stop generation
2. Present the false value to user
3. Ask: "This ticket requests attribute X with value false. False values typically disable features. Should this be true instead, or is this intentionally a stop condition?"
4. Only proceed after user confirmation

### Ticket Number to Class Name Conversion

**Rule**: Class name is `IAM<number>` (strip all prefixes)

**Examples**:
- IAMTASKS-1999 → `IAM1999.java` (strip "TASKS")
- IAM-2152 → `IAM2152.java` (strip dash)
- IAMTASKS-999 → `IAM999.java`

**Implementation**:
1. Extract ticket number from Jira ID
2. Remove project prefix (IAMTASKS, IAM, etc.)
3. Remove separators (dashes)
4. Result: `IAM<number>`

## Handling Ambiguity

When requirements are unclear:
1. Look for similar existing tickets
2. Check base template (if mentioned) for defaults
3. **CRITICAL**: Check for false value anti-pattern first
4. Ask user for clarification on:
   - Exact SKU names
   - Product identification
   - Whether to sweep existing licenses
   - Exact entitlement names and types
   - **Any false values or zero values for new attributes**
