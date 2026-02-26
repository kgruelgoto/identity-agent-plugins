# Resource Schemas

This document describes the schemas for Account, User, License, and Organization resources, including their standard attributes and extendable schema capabilities.

## Important Concepts

### Extendable Schema

The following resources have **extendable schemas**, meaning they can have custom attributes beyond the standard schema:

- ✅ **Account** - Can have custom attributes
- ✅ **User** - Can have custom attributes
- ✅ **License** - Can have custom attributes (called entitlements in product namespace)
- ✅ **Organization** - Can have custom attributes

**Rules for custom attributes**:
- Attribute names must be ≤ 64 characters
- Can be any valid JSON type
- Queryable via "scan by attribute" endpoints
- Not limited to the attributes listed in this document

### Product Namespace (Schemaless)

Some resources have a **schemaless product namespace** where product-specific settings can be stored:

- **Account**: `/accounts/{key}/products/{productName}` - Product settings
- **User**: `/users/{key}/products/{productName}` - Product settings
- **License**: `/licenses/{key}/products/{productName}` - Product entitlements
- **Plan**: Plans have product settings (not covered in this plugin)

The product namespace is completely schemaless - any JSON structure is valid.

---

## Account Resource Schema

**Extendable**: ✅ Yes
**Product Namespace**: ✅ Yes (schemaless)
**Reference**: https://iamdocs.serversdev.getgo.com/account/resources/account.html

### Standard Attributes

| Name | Type | Category | Description |
|------|------|----------|-------------|
| `key` | Number | generated_identifier | Primary identifier, automatically assigned, immutable, 64-bit integer |
| `createtime` | Number | generated | Unix epoch time (milliseconds) when account was created |
| `parentkey` | Number | read_write | Parent account key for parent-child relationships |
| `parentrolesets` | String Array | read_write | Array of role set names for parent-child relationship filter |
| `parentroles` | String Array | projection | Resolved role names from role sets |

### Custom Attributes

Accounts can have **any custom attribute** beyond the standard schema. Common examples:
- `companyName` - Company name
- `industry` - Industry type
- `region` - Geographic region
- `tier` - Service tier
- `externalId` - External system ID
- Any other custom fields your organization uses

### Filtering by Attributes

```bash
# Find accounts by standard attribute
accsvc GET "/v2/accounts?filter=parentkey=6472352565130037257"

# Scan by custom attribute (requires exact match)
accsvc GET "/v2/accounts?name=companyName&value=\"Acme+Corp\"&count=50"

# Scan by custom attribute with range
accsvc GET "/v2/accounts?name=tier&value=\"premium\"&startKey=1000&endKey=9999999999&count=100"
```

---

## User Resource Schema

**Extendable**: ✅ Yes
**Product Namespace**: ✅ Yes (schemaless)
**Reference**: https://iamdocs.serversdev.getgo.com/account/resources/user.html

### Standard Attributes

| Name | Type | Category | Description |
|------|------|----------|-------------|
| `key` | Number | generated_identifier | Primary identifier, automatically assigned, immutable, 64-bit integer |
| `email` | String | read_write_identifier | Secondary identifier, case-insensitive, max 128 chars |
| `firstname` | String | read_write | First (given) name, max 128 chars |
| `lastname` | String | read_write | Last (family) name, max 128 chars |
| `createtime` | Number | generated | Unix epoch time (milliseconds) when user was created |
| `accountkeys` | Number Array | projection | Account associations (64-bit integers) |
| `organizationkey` | Number | projection | Organization membership (64-bit integer) |
| `locale` | String | read_write | ISO 639 language code (e.g., "en_US") |
| `timezone` | String | read_write | tz database timezone (e.g., "America/New_York") |
| `status` | String | read_write | User status (if "suspended", user is disabled) |
| `password` | String | read_write | Encoded password (write plain-text, read encoded) |
| `passwordset` | Boolean | read_only | Whether password is set |
| `lockout` | String | read_only | Lock status: "SOFT" or "HARD" if locked |
| `origin` | String | write_once | User origin, set only during creation |
| `emailverified` | Boolean | write_only | Email verification flag |
| `emailverificationtime` | Number | generated | Unix epoch time when email was verified |
| `emailverificationmethod` | String | read_write | Method used for email verification |
| `residencyregion` | String | read_write | Data residency region: "UNITED_STATES", "EUROPE", "INDIA" |
| `strongpasswordpolicy` | Boolean | read_write | Strong password policy enabled |
| `passwordupdatetime` | Number | generated | Unix epoch time when password was last updated |

### Custom Attributes

Users can have **any custom attribute** beyond the standard schema. Common examples:
- `title` - Job title
- `department` - Department name
- `employeeId` - Employee ID
- `phoneNumber` - Phone number
- `manager` - Manager name or ID
- `customField1`, `customField2`, etc.
- Any other custom fields your organization uses

### Filtering by Attributes

```bash
# Find users by standard attribute
accsvc GET "/v2/accounts/123/users?filter=firstname+eq+\"John\""

# Find users by email pattern
accsvc GET "/v2/accounts/123/users?filter=email+co+\"@acme.com\""

# Scan by custom attribute
accsvc GET "/v2/users?name=department&value=\"Engineering\"&count=50"

# Scan by custom attribute in account context
accsvc GET "/v2/accounts/123/users?name=title&value=\"Engineer\"&count=50"

# Scan users by domain
accsvc GET "/v2/users?domain=acme.com&count=100"
```

### Filter Expressions

User filtering supports SCIM-like filter expressions:
- `eq` - Equals: `firstName eq "John"`
- `sw` - Starts with: `email sw "john"`
- `co` - Contains: `email co "@acme.com"`
- `gt` - Greater than (numbers): `createtime gt 1234567890`
- `lt` - Less than (numbers): `createtime lt 9999999999`

---

## License Resource Schema

**Extendable**: ✅ Yes
**Product Namespace**: ✅ Yes (schemaless) - called "entitlements"
**Reference**: https://iamdocs.serversdev.getgo.com/account/resources/license.html

### Standard Attributes

| Name | Type | Category | Description |
|------|------|----------|-------------|
| `key` | Number | generated_identifier | Primary identifier, automatically assigned, immutable, 64-bit integer |
| `accountkey` | Number | projection | Account the license belongs to, immutable |
| `seats` | Number | read_write | Max users (null = unlimited), non-negative integer |
| `remaining` | Number | read_only | Available seats (seats - assigned users) |
| `enabled` | Boolean | read_write | Whether license is active (confers roles/entitlements) |
| `weighted` | Boolean | write_once | Whether license uses weighted assignments |
| `roles` | String Array | read_write | Role names granted by this license |
| `userkeys` | Number Array | projection | Users assigned to this license |
| `users` | Object Array | projection | User details (for weighted licenses only) |
| `type` | String | read_write | License type: "named" or "concurrent" |
| `description` | String | read_write | Human-readable license description |
| `name` | String | read_write | License name |
| `sku` | String | read_write | SKU identifier |
| `channel` | String | read_write | Distribution channel |
| `servicetype` | String | read_write | Service type classification |
| `externallymanaged` | Boolean | read_write | Whether managed by external system |

### Custom Attributes

Licenses can have **any custom attribute** beyond the standard schema. Common examples:
- `subscriptionId` - External subscription ID
- `purchaseDate` - Purchase date
- `renewalDate` - Renewal date
- `tier` - License tier
- Any other custom fields

### Product Entitlements (Schemaless)

License entitlements are product-specific settings in the product namespace:

```bash
# Get entitlements for a product
accsvc GET /v2/licenses/123/products/jive

# Response is completely schemaless - any JSON structure
{
  "maxMeetings": 100,
  "recordingEnabled": true,
  "customFeatureFlag": "value",
  "nested": {
    "property": "value"
  }
}
```

### Filtering by Attributes

```bash
# Find licenses by standard attribute
accsvc GET "/v2/accounts/123/licenses?filter=name=Jive*"

# Find licenses by role
accsvc GET "/v2/accounts/123/licenses?roles=ROLE_G2M_ORGANIZER"

# Scan by custom attribute
accsvc GET "/v2/licenses?name=tier&value=\"premium\"&count=50"

# Scan by role
accsvc GET "/v2/licenses?role=ROLE_JIVE_ADMIN&count=100"
```

---

## Organization Resource Schema

**Extendable**: ✅ Yes
**Product Namespace**: ❌ No
**Reference**: https://iamdocs.serversdev.getgo.com/account/resources/organization.html

### Standard Attributes

| Name | Type | Category | Description |
|------|------|----------|-------------|
| `key` | Number | generated_identifier | Primary identifier, automatically assigned, immutable, 64-bit integer |
| `createtime` | Number | generated | Unix epoch time (milliseconds) when organization was created |
| `name` | String | read_write | Organization name |
| `users` | Object Array | projection | Users in this organization (key + optional roles) |
| `users.key` | Number | - | User key |
| `users.roles` | String Array | - | User's organization roles (e.g., "ROLE_ORG_WRITE", "ROLE_ORG_READ") |
| `domains` | String Array | projection | Domain names owned by this organization |
| `clients` | Object Array | projection | OAuth clients associated with organization |
| `clients.clientId` | String | - | OAuth client ID |
| `clients.roles` | String Array | - | Client's organization roles |

### Custom Attributes

Organizations can have **any custom attribute** beyond the standard schema. Common examples:
- `industry` - Industry classification
- `size` - Organization size
- `country` - Country
- `externalId` - External system ID
- Any other custom fields

### Filtering by Attributes

```bash
# Find organizations by name
accsvc GET "/v2/organizations?filter=name=Acme*&maxResults=10"

# Find organizations by domain
accsvc GET "/v2/organizations?domains=acme.com"

# Find organizations by user
accsvc GET "/v2/organizations?userKeys=123456789"

# Find organizations by OAuth client
accsvc GET "/v2/organizations?clientId=6db2c064-b2f4-469a-aeae-9e81f818f367"
```

---

## Key Takeaways

### 1. **All Major Resources Are Extendable**
- You can query by **any custom attribute**, not just the documented schema
- Use "scan by attribute" endpoints to find resources by custom fields

### 2. **Different Query Methods**

**Filter (Find operations)**:
- Uses SCIM-like expressions: `firstName eq "John"`
- Works on most standard fields
- Does NOT work on custom attributes directly
- Limited to 100 results

**Scan by Attribute**:
- Works on **both standard AND custom attributes**
- Exact match: `?name=attributeName&value="exactValue"`
- Supports range constraints (startKey/endKey)
- Paginated (count parameter)

### 3. **Product Settings Are Completely Schemaless**

Product namespaces have **no schema** - any JSON is valid:
- Account settings: `/accounts/{key}/products/{productName}`
- User settings: `/users/{key}/products/{productName}`
- License entitlements: `/licenses/{key}/products/{productName}`

### 4. **Property Categories**

- `generated_identifier` - Auto-assigned primary keys, immutable
- `generated` - Auto-assigned values (timestamps)
- `read_write` - Can be read and modified
- `read_only` - Can be read but not modified directly
- `write_only` - Can be written but not read back
- `write_once` - Can only be set during creation
- `projection` - Computed/derived values

## Examples

### Query by Custom Attribute

```bash
# Find accounts with custom "tier" attribute
accsvc GET "/v2/accounts?name=tier&value=\"premium\"&count=50"

# Find users with custom "department" attribute
accsvc GET "/v2/users?name=department&value=\"Engineering\"&count=50"

# Find licenses with custom "subscriptionId"
accsvc GET "/v2/licenses?name=subscriptionId&value=\"SUB-12345\"&count=10"
```

### Query Product Settings

```bash
# Get account's jive settings (schemaless)
accsvc GET /v2/accounts/123/products/jive

# Get user's jive settings (schemaless)
accsvc GET /v2/users/456/products/jive

# Get license entitlements for jive (schemaless)
accsvc GET /v2/licenses/789/products/jive
```

### Complex Filtering

```bash
# Users by email domain
accsvc GET "/v2/users?domain=acme.com&count=100"

# Users by residency region (standard attribute)
accsvc GET "/v2/users?name=residencyregion&value=\"EUROPE\"&count=50"

# Licenses by enabled status + role
accsvc GET "/v2/accounts/123/licenses?roles=ROLE_G2M_ORGANIZER" | jq '.[] | select(.enabled == true)'
```

## Reference Documentation

Full schema documentation: https://iamdocs.serversdev.getgo.com/account/resources/
