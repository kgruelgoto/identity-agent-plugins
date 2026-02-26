# License Endpoints Reference

This document lists all GET operations for License resources in the Account Service API.

All paths should be prefixed with `/v2` (e.g., `/v2/licenses/123`).

## Basic License Operations

### Get License
**Operation**: `getLicense`
**Method**: `GET`
**Path**: `/licenses/{licenseKey}`

**Path Variables**:
- `{licenseKey}` - Key of target license

**Description**: Retrieves a single license by its key.

**Response**: License object with key, accountkey, seats, remaining, enabled, roles array, userkeys array, and other properties.

---

### Get Licenses By Keys (Batch)
**Operation**: `getLicensesByKeys`
**Method**: `GET`
**Path**: `/licenses/{licenseKeys}?batch=true`

**Path Variables**:
- `{licenseKeys}` - Comma-separated list of license keys (up to 100 keys)

**Query Parameters**:
- `batch` (required) - Must be `true`

**Description**: Retrieves multiple licenses by their keys in a single request.

**Response**: Array of license objects.

---

### Get Licenses
**Operation**: `getLicenses`
**Method**: `GET`
**Path**: `/accounts/{accountKeys}/licenses`

**Path Variables**:
- `{accountKeys}` - Comma-separated list of account keys (up to 100 keys)

**Query Parameters**:
- `roles` (optional) - Comma-separated list of role names to filter licenses. Returns licenses containing any of the listed roles.
- `includeUsers` (optional) - Comma-separated list of user keys to filter the userkeys array in responses.

**Description**: Retrieves all licenses for one or more accounts with optional role and user filtering.

**Response**: Array of license objects.

---

### Find Licenses
**Operation**: `findLicenses`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/licenses?filter={filter}`

**Path Variables**:
- `{accountKey}` - Key of target account

**Query Parameters**:
- `filter` (required) - Comma-separated list of equals-delimited key-value pairs. Value may contain wildcards `*`. Cannot search: `key`, `accountkey`, `remaining`, `seats`, `enabled`, `roles`, `userkeys`.

**Description**: Searches for licenses within an account matching filter criteria.

**Response**: Array of license objects.

---

### Get User Licenses
**Operation**: `getUserLicenses`
**Method**: `GET`
**Path**: `/users/{userKeys}/licenses`

**Path Variables**:
- `{userKeys}` - Comma-separated list of user keys (up to 100 keys)

**Query Parameters**:
- `roles` (optional) - Comma-separated list of role names to filter licenses
- `includeUsers` (optional) - Comma-separated list of user keys to filter userkeys array

**Description**: Retrieves all licenses associated with one or more users.

**Response**: Array of license objects.

---

## License Users Operations

### Get License Users
**Operation**: `getLicenseUsers`
**Method**: `GET`
**Path**: `/licenses/{licenseKey}/users`

**Path Variables**:
- `{licenseKey}` - Key of target license

**Description**: Retrieves the list of user keys assigned to a license. Same as the `userkeys` field in the license resource.

**Response**: Array of user key integers.

---

## License Products & Entitlements

### Get License Products
**Operation**: `getLicenseProducts`
**Method**: `GET`
**Path**: `/licenses/{licenseKey}/products`

**Path Variables**:
- `{licenseKey}` - Key of target license

**Description**: Retrieves the list of product names associated with a license.

**Response**: Array of product name strings (e.g., `["g2m", "g2w"]`).

---

### Get License Entitlements
**Operation**: `getLicenseEntitlements`
**Method**: `GET`
**Path**: `/licenses/{licenseKey}/products/{productName}`

**Path Variables**:
- `{licenseKey}` - Key of target license
- `{productName}` - Name of target product

**Description**: Retrieves product-specific entitlements for a license.

**Response**: Object with entitlement properties.

---

### Get License Entitlements By Keys (Batch)
**Operation**: `getLicenseEntitlementsByKeys`
**Method**: `GET`
**Path**: `/licenses/{licenseKeys}/products/{productName}?batch=true`

**Path Variables**:
- `{licenseKeys}` - Comma-separated list of license keys (up to 100 keys)
- `{productName}` - Name of target product

**Query Parameters**:
- `batch` (required) - Must be `true`

**Description**: Retrieves product entitlements for multiple licenses in a single request.

**Response**: Array of objects with license key and product entitlements.

---

## License Scan Operations

### Scan Licenses By Key
**Operation**: `scanLicensesByKey`
**Method**: `GET`
**Path**: `/licenses`

**Query Parameters**:
- `startKey` (optional) - Lower bound license range key
- `startInclusive` (optional) - Whether lower bound is inclusive (default: `true`)
- `endKey` (optional) - Upper bound license range key
- `endInclusive` (optional) - Whether upper bound is inclusive (default: `true`)
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans licenses with key-based range and pagination. Useful for sequential or parallel scanning.

**Response**: Array of license objects (up to `count` results).

---

### Scan Licenses By Attribute
**Operation**: `scanLicensesByAttribute`
**Method**: `GET`
**Path**: `/licenses?name={name}&value={value}`

**Query Parameters**:
- `name` (required) - Attribute name
- `value` (required) - Attribute value (JSON literal)
- `product` (optional) - Product context for the scan
- `startKey` (optional) - Lower bound license range key
- `startInclusive` (optional) - Whether lower bound is inclusive (default: `true`)
- `endKey` (optional) - Upper bound license range key
- `endInclusive` (optional) - Whether upper bound is inclusive (default: `true`)
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans licenses by custom attribute with optional range constraints.

**Response**: Array of license objects (up to `count` results).

---

### Scan Licenses By Role
**Operation**: `scanLicensesByRole`
**Method**: `GET`
**Path**: `/licenses?role={role}`

**Query Parameters**:
- `role` (required) - Role name to filter licenses
- `startKey` (optional) - Lower bound license key
- `startInclusive` (optional) - Whether lower bound is inclusive (default: `true`)
- `endKey` (optional) - Upper bound license key
- `endInclusive` (optional) - Whether upper bound is inclusive (default: `true`)
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans licenses that contain a specific role.

**Response**: Array of license objects (up to `count` results).

---

## Usage Examples

```bash
# Get single license
accsvc GET /v2/licenses/123456789

# Get multiple licenses (batch)
accsvc GET "/v2/licenses/123,456,789?batch=true"

# Get licenses for account
accsvc GET /v2/accounts/6472352565130037257/licenses

# Get licenses for account filtered by role
accsvc GET "/v2/accounts/6472352565130037257/licenses?roles=ROLE_G2M_ORGANIZER,ROLE_G2W_ORGANIZER"

# Find licenses with filter
accsvc GET "/v2/accounts/6472352565130037257/licenses?filter=name=Jive*"

# Get user's licenses
accsvc GET /v2/users/123456789/licenses

# Get users assigned to license
accsvc GET /v2/licenses/123456789/users

# Get license products
accsvc GET /v2/licenses/123456789/products

# Get license entitlements for product
accsvc GET /v2/licenses/123456789/products/jive

# Get batch license entitlements
accsvc GET "/v2/licenses/123,456/products/jive?batch=true"

# Scan licenses by role
accsvc GET "/v2/licenses?role=ROLE_G2M_ORGANIZER&count=50"

# Scan licenses by custom attribute
accsvc GET "/v2/licenses?name=customAttr&value=\"someValue\"&count=20"
```

## Notes

- License keys are 64-bit integers
- License objects include:
  - `seats` - Total number of seats
  - `remaining` - Available seats not yet assigned
  - `enabled` - Whether the license is active
  - `roles` - Array of role names granted by the license
  - `userkeys` - Array of user keys assigned to the license
- Maximum 100 keys per batch operation
- Role filtering uses OR logic (returns licenses with any of the specified roles)
- Scan operations support range-based pagination for large result sets
- Entitlements are product-specific settings/permissions

## Schema & Custom Attributes

**Licenses have an extendable schema** - they can have custom attributes beyond the standard schema.

**Standard attributes**: `key`, `accountkey`, `seats`, `remaining`, `enabled`, `roles`, `userkeys`, `type`, `description`, `name`, `sku`, `channel`, `servicetype`, etc.

**Custom attributes**: Licenses can have ANY custom attribute (max 64 char name). Query them using scan operations:
```bash
# Example: Query by custom "tier" attribute
accsvc GET "/v2/licenses?name=tier&value=\"premium\"&count=50"

# Example: Query by custom "subscriptionId" attribute
accsvc GET "/v2/licenses?name=subscriptionId&value=\"SUB-12345\"&count=10"

# Example: Query by custom attribute in account context
accsvc GET "/v2/accounts/123/licenses?name=externalId&value=\"EXT-789\""
```

**Product entitlements are completely schemaless** - `/licenses/{key}/products/{productName}` can contain any JSON structure:
```bash
# Get license entitlements (schemaless)
accsvc GET /v2/licenses/123/products/jive
# Response can be any JSON: {"maxMeetings": 100, "recordingEnabled": true, ...}
```

See `schemas.md` for complete license schema documentation.
