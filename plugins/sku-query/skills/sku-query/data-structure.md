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
- `weighted`: Whether SKU uses weighted licensing
- `maxAttendees`: Max meeting attendees

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
- `provides`: Array of products/features this SKU provides
- `requires`: Array of products required
- `requiresAny`: Array of arrays for "one of these" requirements
- `childSkus`: Array of child SKU names

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
