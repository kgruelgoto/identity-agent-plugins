# Account Endpoints Reference

This document lists all GET operations for Account resources in the Account Service API.

All paths should be prefixed with `/v2` (e.g., `/v2/accounts/123`).

## Account Operations

### Get Account
**Operation**: `getAccount`
**Method**: `GET`
**Path**: `/accounts/{accountKey}`

**Path Variables**:
- `{accountKey}` - Key of target account

**Description**: Retrieves a single account by its key.

**Response**: Account object with name, key, createTime, and other properties.

---

### Find Accounts
**Operation**: `findAccounts`
**Method**: `GET`
**Path**: `/accounts?filter={filter}&product={product}&maxResults={max}`

**Query Parameters**:
- `filter` (required) - Equals-delimited key-value pair. Value may contain trailing wildcard `*`. The `key` and `createtime` attributes are not searchable.
- `product` (optional) - Valid product name or wildcard `*` to signify any product
- `maxResults` (optional) - Maximum number of results (1-100, default: 100)

**Description**: Searches for accounts matching filter criteria. Returns up to 100 accounts non-deterministically if more than 100 match.

**Response**: Array of account objects augmented with `plans` property.

---

### Get Accounts (Batch)
**Operation**: `getAccounts`
**Method**: `GET`
**Path**: `/accounts/{accountKeys}?batch=true`

**Path Variables**:
- `{accountKeys}` - Comma-separated list of account keys (up to 40 keys)

**Query Parameters**:
- `batch` (required) - Must be `true`

**Description**: Retrieves multiple accounts by their keys in a single request.

**Response**: Array of account objects.

---

### Get Account Plans
**Operation**: `getAccountPlans`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/plans`

**Path Variables**:
- `{accountKey}` - Key of target account

**Description**: Retrieves the list of plan names associated with an account.

**Response**: Array of plan name strings (e.g., `["plan1", "plan2"]`).

---

### Get Account Products
**Operation**: `getAccountProducts`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/products`

**Path Variables**:
- `{accountKey}` - Key of target account

**Description**: Retrieves the list of product names associated with account plans. **Warning**: This yields products from account plans, not entitlements. Use `getLicenses` for entitlements.

**Response**: Array of product name strings (e.g., `["g2m", "jive"]`).

---

### Get Account Settings
**Operation**: `getAccountSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/products/{productName}`

**Path Variables**:
- `{accountKey}` - Key of target account
- `{productName}` - Name of target product

**Query Parameters**:
- `inherit` (optional) - Boolean indicating whether to apply inheritance from plans (default: `true`)
- `withLicenses` (optional) - Boolean indicating whether to apply inheritance from licenses

**Description**: Retrieves product-specific settings for an account with optional inheritance.

**Response**: Object with product settings.

---

### Get Accounts Settings (Batch)
**Operation**: `getAccountsSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKeys}/products/{productName}?batch=true`

**Path Variables**:
- `{accountKeys}` - Comma-separated list of account keys (up to 100 keys)
- `{productName}` - Name of target product

**Query Parameters**:
- `batch` (required) - Must be `true`
- `inherit` (optional) - Boolean indicating whether to apply inheritance from plans (default: `true`)

**Description**: Retrieves product settings for multiple accounts in a single request.

**Response**: Object mapping account keys to settings.

---

### Scan Accounts By Attribute
**Operation**: `scanAccountsByAttribute`
**Method**: `GET`
**Path**: `/accounts?name={name}&value={value}`

**Query Parameters**:
- `name` (required) - Attribute name
- `value` (required) - Attribute value (JSON literal)
- `product` (optional) - Product context for the scan
- `startKey` (optional) - Lower bound account range key
- `startInclusive` (optional) - Whether lower bound is inclusive (default: `true`)
- `endKey` (optional) - Upper bound account range key
- `endInclusive` (optional) - Whether upper bound is inclusive (default: `true`)
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans accounts by custom attribute name-value pairs with optional range constraints.

**Response**: Array of matching account objects (up to `count` results).

---

### Scan Accounts By Parent Key
**Operation**: `scanAccountsByParentKey`
**Method**: `GET`
**Path**: `/accounts?parentKey={parentKey}`

**Query Parameters**:
- `parentKey` (required) - Target parent account key
- `startKey` (optional) - Exclusive lower bound child account range key
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans child accounts by parent key with optional pagination.

**Response**: Array of child account objects (up to `count` results).

---

## Usage Examples

```bash
# Get single account
accsvc GET /v2/accounts/6472352565130037257

# Get account products
accsvc GET /v2/accounts/6472352565130037257/products

# Get account settings for jive product
accsvc GET /v2/accounts/6472352565130037257/products/jive

# Find accounts by name
accsvc GET "/v2/accounts?filter=name=Acme*&maxResults=10"

# Get multiple accounts (batch)
accsvc GET "/v2/accounts/123,456,789?batch=true"

# Scan by custom attribute
accsvc GET "/v2/accounts?name=customAttr&value=\"someValue\"&count=20"

# Get child accounts
accsvc GET "/v2/accounts?parentKey=6472352565130037257&count=50"
```

## Notes

- All account keys are 64-bit integers
- Batch operations have limits (40 for getAccounts, 100 for getAccountsSettings)
- Some operations support case control filtering
- Product settings support inheritance from plans and licenses

## Schema & Custom Attributes

**Accounts have an extendable schema** - they can have custom attributes beyond the standard schema.

**Standard attributes**: `key`, `createtime`, `parentkey`, `parentrolesets`, `parentroles`

**Custom attributes**: Accounts can have ANY custom attribute (max 64 char name). Query them using "Scan Accounts By Attribute":
```bash
# Example: Query by custom "tier" attribute
accsvc GET "/v2/accounts?name=tier&value=\"premium\"&count=50"

# Example: Query by custom "companyName" attribute
accsvc GET "/v2/accounts?name=companyName&value=\"Acme+Corp\"&count=20"
```

**Product settings are schemaless** - `/accounts/{key}/products/{productName}` can contain any JSON structure.

See `schemas.md` for complete account schema documentation.
