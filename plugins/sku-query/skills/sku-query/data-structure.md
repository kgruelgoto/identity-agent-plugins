# SKU Data Structure Reference

## Complete SKU Structure

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

## Common Fields to Query

### License Attributes
Top-level SKU metadata:
- `description`: Human-readable SKU name
- `roles`: Array of roles granted
- `devicesAllowed`: Whether devices are allowed
- `weighted`: Whether SKU uses weighted licensing (true = weighted, null/false = per-license)
- `maxAttendees`: Max meeting attendees
- `isUnlimitedSku`: Whether SKU has unlimited billing (true = unlimited, null/false = per-license)
- `isAddonSku`: Whether this is an add-on SKU
- `isChildSku`: Whether this is a child SKU

### License Entitlements (per-license)
Features granted to each individual license holder.

Common fields by product:
- **jive**: `advancedivrprovisioned`, `e911provisioned`, etc.
- **g2w**: `transcriptsprovisioned`, `recordingsprovisioned`, etc.
- **g2m**: `transcriptsprovisioned`, `summaryprovisioned`, `breakoutsprovisioned`, etc.
- **ccaas**: Various contact center features

### Account Entitlements (account-level)
Settings and limits applied at the account level.

Common fields by product:
- **jive**: `transcriptionallowed`, `maxcallqueues`, `maxdids`, `advancedreportingallowed`, etc.
- **g2w**: Various webinar settings
- **ccaas**: `aicallanalysis`, `sku`, etc.

### Relationships
How SKUs depend on or provide other products:
- `provides`: Array of products/features this SKU provides (e.g., `["g2c"]` means grants access to GoTo Connect)
- `requires`: Array of products required (e.g., `["g2c"]` means needs GoTo Connect to function)
- `requiresAny`: Array of arrays for "one of these" requirements (e.g., `[["g2c", "g2c_legacy"]]` means needs either)
- `childSkus`: Array of child SKU names

### Billing Types
Determine how a SKU is billed:
- **Per-license**: `isUnlimitedSku` is null/false AND `weighted` is null/false
- **Unlimited**: `isUnlimitedSku` is true
- **Weighted**: `weighted` is true (none currently exist in data)

## Product Keys

Entitlements are nested under product keys:
- `jive` - GoTo Connect
- `g2w` - GoTo Webinar
- `g2m` - GoTo Meeting
- `g2t` - GoTo Training
- `ccaas` - Contact Center
- `resolve` - GoTo Resolve

## Key Differences

### License vs Account Entitlements

**License Entitlements** - Applied per user license:
- Example: `licenseEntitlements.g2w.transcriptsprovisioned`
- Each user with this license gets the feature

**Account Entitlements** - Applied at account level:
- Example: `accountEntitlements.jive.transcriptionallowed`
- Controls account-wide settings or limits
- May enable/disable features for all users

## Querying Nested Structures

When querying entitlements, use full paths:

```bash
# License entitlement
.licenseEntitlements.jive.advancedivrprovisioned

# Account entitlement
.accountEntitlements.jive.advancedreportingallowed

# Check if entitlements exist
(.licenseEntitlements != null and .licenseEntitlements != {})
```

## Property Name Casing

**Important**: Property names have different casing rules depending on their location:

### licenseEntitlements and accountEntitlements
Property names are **always lowercase** in the data:
- `dialPlanSmsNodeProvisioned` → `dialplansmsnodeprovisioned`
- `transcriptsProvisioned` → `transcriptsprovisioned`

When querying, either:
1. Use lowercase directly: `.accountEntitlements.jive.dialplansmsnodeprovisioned`
2. Use case-insensitive matching with jq:
```bash
jq --arg prop "dialplansmsnodeprovisioned" '.[] | select(
  .accountEntitlements.jive | to_entries[] | select(.key | ascii_downcase == $prop)
)'
```

### licenseAttributes
Property names are **case-sensitive** and must match exactly:
- `.licenseAttributes.description`
- `.licenseAttributes.devicesAllowed`

**Best practice**: For entitlements, always normalize property names to lowercase. For licenseAttributes, use exact casing.
