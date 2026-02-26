# Organization Endpoints Reference

This document lists all GET operations for Organization resources in the Account Service API.

All paths should be prefixed with `/v2` (e.g., `/v2/organizations/123`).

## Organization Operations

### Get Organization
**Operation**: `getOrganization`
**Method**: `GET`
**Path**: `/organizations/{organizationKey}`

**Path Variables**:
- `{organizationKey}` - Key of target organization

**Description**: Retrieves a single organization by its key.

**Response**: Organization object with key, name, users array (with optional roles), domains array, and clients array.

---

### Find Organizations
**Operation**: `findOrganizations`
**Method**: `GET`
**Path**: `/organizations?filter={filter}&maxResults={max}`

**Query Parameters**:
- `filter` (required) - Equals-delimited key-value pair (e.g., `name=Acme`). Trailing wildcards `*` allowed. Cannot include `key`, `createtime`, `users`, or `domains` attributes.
- `maxResults` (optional) - Maximum number of results to return (default: 100)

**Description**: Searches for organizations matching filter criteria.

**Response**: Array of organization objects with users, domains, and clients.

---

### Find Organizations By ClientId
**Operation**: `findOrganizationsByClientId`
**Method**: `GET`
**Path**: `/organizations?clientId={clientId}`

**Query Parameters**:
- `clientId` (required) - OAuth client ID

**Description**: Finds all organizations associated with a specific OAuth client ID.

**Response**: Array of organization objects with users, domains, and clients.

---

### Find Organizations By Domains
**Operation**: `findOrganizationsByDomains`
**Method**: `GET`
**Path**: `/organizations?domains={domains}`

**Query Parameters**:
- `domains` (required) - Comma-separated list of domain names (1-100 domains)

**Description**: Finds all organizations that have one or more of the specified domains.

**Response**: Array of organization objects with users, domains, and clients.

---

### Find Organizations By Users
**Operation**: `findOrganizationsByUsers`
**Method**: `GET`
**Path**: `/organizations?userKeys={userKeys}`

**Query Parameters**:
- `userKeys` (required) - Comma-separated list of user keys (1-100 users)

**Description**: Finds all organizations that have one or more of the specified users as members.

**Response**: Array of organization objects with users, domains, and clients.

---

## Usage Examples

```bash
# Get single organization
accsvc GET /v2/organizations/123456789

# Find organizations by name
accsvc GET "/v2/organizations?filter=name=Acme*&maxResults=10"

# Find organizations by domain
accsvc GET "/v2/organizations?domains=acme.com,example.com"

# Find organizations by user membership
accsvc GET "/v2/organizations?userKeys=123456789,987654321"

# Find organizations by OAuth client ID
accsvc GET "/v2/organizations?clientId=6db2c064-b2f4-469a-aeae-9e81f818f367"
```

## Notes

- Organization keys are 64-bit integers
- Organization responses include:
  - `users` array with optional per-user `roles` arrays
  - `domains` array of domain name strings
  - `clients` array with `clientId` and optional `roles` arrays
- Maximum 100 domains or users per batch query
- Wildcards only allowed at end of filter values
- Case control filtering is supported

## Schema & Custom Attributes

**Organizations have an extendable schema** - they can have custom attributes beyond the standard schema.

**Standard attributes**: `key`, `createtime`, `name`, `users`, `domains`, `clients`

**Custom attributes**: Organizations can have ANY custom attribute (max 64 char name). Common examples:
```bash
# Example: Query by custom "industry" attribute
# (Note: Organization scan by attribute not currently exposed in API,
# but custom attributes can be set and retrieved)

# Get organization with custom attributes
accsvc GET /v2/organizations/123
# Response includes both standard and custom attributes:
# {"key": 123, "name": "Acme", "industry": "Technology", "size": "Enterprise", ...}
```

**Note**: Organizations do NOT have a product namespace (unlike accounts, users, and licenses).

See `schemas.md` for complete organization schema documentation.
