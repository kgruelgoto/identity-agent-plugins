# User Endpoints Reference

This document lists all GET operations for User resources in the Account Service API.

All paths should be prefixed with `/v2` (e.g., `/v2/users/123`).

## Basic User Operations

### Get User
**Operation**: `getUser`
**Method**: `GET`
**Path**: `/users/{userKey}`

**Path Variables**:
- `{userKey}` - Key of target user

**Query Parameters**:
- `includeDeleted` (optional) - Include deleted users with `deletetime` attribute (default: `false`)
- `includeConflicts` (optional) - Include conflicting staged user details (default: `false`)
- `includeStagedUsers` (optional) - Include non-conflicting staged user details (default: `false`)

**Description**: Retrieves a single user by key.

---

### Get Users (Batch)
**Operation**: `getUsers`
**Method**: `GET`
**Path**: `/users/{userKeys}?batch=true`

**Path Variables**:
- `{userKeys}` - Comma-separated list of user keys

**Query Parameters**:
- `batch` (required) - Must be `true`

**Description**: Retrieves multiple users by their keys in a single request.

---

### Get User By Email
**Operation**: `getUserByEmail`
**Method**: `GET`
**Path**: `/users?email={email}`

**Query Parameters**:
- `email` (required) - Email address of the target user
- `includeConflicts` (optional) - Include conflicting staged user details (default: `false`)

**Description**: Retrieves a user by email address.

---

### Get User By Credentials
**Operation**: `getUserByCredentials`
**Method**: `GET`
**Path**: `/users?email={email}&password={password}`

**Query Parameters**:
- `email` (required) - User's email address
- `password` (required) - User's password

**Description**: Authenticates and retrieves user by email/password credentials.

---

### Get User By Username Credentials
**Operation**: `getUserByUsernameCredentials`
**Method**: `GET`
**Path**: `/users?username={username}&password={password}`

**Query Parameters**:
- `username` (required) - User's username
- `password` (required) - User's password

**Description**: Authenticates and retrieves user by username/password credentials.

---

### Get Emails
**Operation**: `getEmails`
**Method**: `GET`
**Path**: `/users/{userKeys}/emails?batch=true`

**Path Variables**:
- `{userKeys}` - Comma-separated list of user keys

**Query Parameters**:
- `batch` (required) - Must be `true`

**Description**: Retrieves email addresses for multiple users.

**Response**: Array of email strings.

---

## Account-User Operations

### Find Account Users
**Operation**: `findAccountUsers`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users`

**Path Variables**:
- `{accountKey}` - Key of target account

**Query Parameters**:
- `filter` (optional) - Query expression for filtering users (filter OR paginate required)
- `paginate` (optional) - Boolean to denote paginated search without filter (filter OR paginate required)
- `sortBy` (optional) - User property name for sorting (default: `key`)
- `sortOrder` (optional) - Sort order: `ascending` or `descending` (default: `ascending`)
- `startIndex` (optional) - Starting index for paginated results (default: 1)
- `count` (optional) - Maximum results per page (1-100, default: 100)

**Description**: Searches/paginates users within an account with filtering and sorting support.

**Response**: Object with `totalResults`, `startIndex`, `itemsPerPage`, and `resources` array.

---

### Get Account Users
**Operation**: `getAccountUsers`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users?ids=false`

**Path Variables**:
- `{accountKey}` - Key of target account

**Query Parameters**:
- `ids` (required) - Must be `false`

**Description**: Retrieves all users in an account (without just IDs).

**Response**: Array of user objects.

---

### Get Account User Keys
**Operation**: `getAccountUserKeys`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users?ids=true`

**Path Variables**:
- `{accountKey}` - Key of target account

**Query Parameters**:
- `ids` (required) - Must be `true`

**Description**: Retrieves only the user keys for all users in an account.

**Response**: Array of user key integers.

---

### Scan Account Users By Attribute
**Operation**: `scanAccountUsersByAttribute`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users?name={name}&value={value}`

**Path Variables**:
- `{accountKey}` - Key of target account

**Query Parameters**:
- `name` (required) - Attribute name
- `value` (required) - Attribute value (JSON literal)
- `startKey` (optional) - Lower bound user range key
- `startInclusive` (optional) - Whether lower bound is inclusive (default: `true`)
- `endKey` (optional) - Upper bound user range key
- `endInclusive` (optional) - Whether upper bound is inclusive (default: `true`)
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans account users by custom attribute with optional range constraints.

---

## Organization-User Operations

### Find Organization Users
**Operation**: `findOrganizationUsers`
**Method**: `GET`
**Path**: `/organizations/{organizationKey}/users`

**Path Variables**:
- `{organizationKey}` - Key of target organization

**Query Parameters**:
- Similar to Find Account Users (filter, paginate, sortBy, sortOrder, startIndex, count)

**Description**: Searches/paginates users within an organization.

---

## User Scan Operations

### Find Users
**Operation**: `findUsers`
**Method**: `GET`
**Path**: `/users?filter={filter}`

**Query Parameters**:
- `filter` (required) - Query expression for filtering users
- `sortBy` (optional) - User property for sorting (default: `key`)
- `sortOrder` (optional) - `ascending` or `descending` (default: `ascending`)
- `startIndex` (optional) - Starting index (default: 1)
- `count` (optional) - Maximum results (1-100, default: 100)

**Description**: Searches users globally with filtering and sorting.

---

### Scan Users By Attribute
**Operation**: `scanUsersByAttribute`
**Method**: `GET`
**Path**: `/users?name={name}&value={value}`

**Query Parameters**:
- `name` (required) - Attribute name
- `value` (required) - Attribute value (JSON literal)
- `startKey`, `startInclusive`, `endKey`, `endInclusive`, `count` - Range and pagination options

**Description**: Scans all users by custom attribute.

---

### Scan Users By Domain
**Operation**: `scanUsersByDomain`
**Method**: `GET`
**Path**: `/users?domain={domain}`

**Query Parameters**:
- `domain` (required) - Email domain name
- `startKey` (optional) - Exclusive lower bound user range key
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans users by email domain.

---

### Scan Users By Key
**Operation**: `scanUsersByKey`
**Method**: `GET`
**Path**: `/users?scan=true`

**Query Parameters**:
- `scan` (required) - Must be `true`
- `startKey` (optional) - Exclusive lower bound user range key
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans all users with key-based pagination.

---

### Scan Users With Direct Roles By Key
**Operation**: `scanUsersWithDirectRolesByKey`
**Method**: `GET`
**Path**: `/users?scan=true&withDirectRoles=true`

**Query Parameters**:
- `scan` (required) - Must be `true`
- `withDirectRoles` (required) - Must be `true`
- `startKey` (optional) - Exclusive lower bound user range key
- `count` (optional) - Maximum results (1-100, default: 10)

**Description**: Scans users who have directly assigned roles.

---

## User Role Operations

### Get User Roles
**Operation**: `getUserRoles`
**Method**: `GET`
**Path**: `/users/{userKey}/roles`

**Path Variables**:
- `{userKey}` - Key of target user

**Query Parameters**:
- `inherit` (optional) - Extend to include user-license roles (default: `true`)
- `accountKey` (optional) - Scope roles to specific account
- `includeDirect` (optional) - Include direct roles when user is not account member (default: `false`)

**Description**: Retrieves roles for a user with optional inheritance and account scoping.

**Response**: Array of role name strings.

---

### Get User Roles By Account
**Operation**: `getUserRolesByAccount`
**Method**: `GET`
**Path**: `/users/{userKey}/roles?byAccounts=true`

**Path Variables**:
- `{userKey}` - Key of target user

**Query Parameters**:
- `byAccounts` (required) - Must be `true`

**Description**: Retrieves user roles grouped by account.

**Response**: Object mapping account keys to role arrays.

---

### Get Account User Roles
**Operation**: `getAccountUserRoles`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users/{userKey}/roles`

**Path Variables**:
- `{accountKey}` - Key of target account
- `{userKey}` - Key of target user

**Description**: Retrieves roles for a specific user in a specific account.

---

## User Settings Operations

### Get User Settings
**Operation**: `getUserSettings`
**Method**: `GET`
**Path**: `/users/{userKey}/products/{productName}`

**Path Variables**:
- `{userKey}` - Key of target user
- `{productName}` - Name of target product

**Query Parameters**:
- `accountKey` (optional) - Scope to specific account
- `inherit` (optional) - Apply inheritance (default: `true`)

**Description**: Retrieves product-specific settings for a user.

---

### Get Account User Settings
**Operation**: `getAccountUserSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users/{userKey}/products/{productName}`

**Path Variables**:
- `{accountKey}` - Key of target account
- `{userKey}` - Key of target user
- `{productName}` - Name of target product

**Query Parameters**:
- `inherit` (optional) - Apply inheritance (default: `true`)

**Description**: Retrieves product settings for user in specific account context.

---

### Get Account Users Settings
**Operation**: `getAccountUsersSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users/products/{productName}?ids=false`

**Path Variables**:
- `{accountKey}` - Key of target account
- `{productName}` - Name of target product

**Query Parameters**:
- `ids` (required) - Must be `false`

**Description**: Retrieves product settings for all users in an account.

---

### Get All Account Users Settings
**Operation**: `getAllAccountUsersSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users/{userKeys}/products/{productName}?batch=true`

**Path Variables**:
- `{accountKey}` - Key of target account
- `{userKeys}` - Comma-separated list of user keys
- `{productName}` - Name of target product

**Query Parameters**:
- `batch` (required) - Must be `true`
- `inherit` (optional) - Apply inheritance (default: `true`)

**Description**: Batch retrieves product settings for multiple users in an account.

---

## User Group Settings Operations

### Get Account User Group Settings
**Operation**: `getAccountUserGroupSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users/{userKey}/groups/{groupKey}/products/{productName}`

**Path Variables**:
- `{accountKey}` - Account key
- `{userKey}` - User key
- `{groupKey}` - Group key
- `{productName}` - Product name

**Description**: Retrieves product settings for user in specific group context.

---

### Get Account User Groups Settings
**Operation**: `getAccountUserGroupsSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/users/{userKey}/groups/products/{productName}`

**Path Variables**:
- `{accountKey}` - Account key
- `{userKey}` - User key
- `{productName}` - Product name

**Description**: Retrieves product settings for user across all groups.

---

### Get Account Group User Settings
**Operation**: `getAccountGroupUserSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/groups/{groupKey}/users/{userKey}/products/{productName}`

**Path Variables**:
- `{accountKey}` - Account key
- `{groupKey}` - Group key
- `{userKey}` - User key
- `{productName}` - Product name

**Description**: Alternative path for group-user product settings.

---

### Get Account Groups User Settings
**Operation**: `getAccountGroupsUserSettings`
**Method**: `GET`
**Path**: `/accounts/{accountKey}/groups/users/{userKey}/products/{productName}`

**Path Variables**:
- `{accountKey}` - Account key
- `{userKey}` - User key
- `{productName}` - Product name

**Description**: Retrieves product settings for user across all groups in account.

---

## Other User Operations

### Get User Account Keys
**Operation**: `getUserAccountKeys`
**Method**: `GET`
**Path**: `/users/{userKey}/accounts?ids=true`

**Path Variables**:
- `{userKey}` - Key of target user

**Query Parameters**:
- `ids` (required) - Must be `true`

**Description**: Retrieves list of account keys the user is a member of.

**Response**: Array of account key integers.

---

### Get User Products
**Operation**: `getUserProducts`
**Method**: `GET`
**Path**: `/users/{userKey}/products`

**Path Variables**:
- `{userKey}` - Key of target user

**Query Parameters**:
- `accountKey` (optional) - Scope to specific account

**Description**: Retrieves list of products available to the user.

**Response**: Array of product name strings.

---

## Usage Examples

```bash
# Get single user
accsvc GET /v2/users/123456789

# Get user by email
accsvc GET "/v2/users?email=user@example.com"

# Get all users in account
accsvc GET "/v2/accounts/6472352565130037257/users?ids=false"

# Find users with filter
accsvc GET "/v2/accounts/6472352565130037257/users?filter=firstName+eq+\"John\"&count=10"

# Get user roles
accsvc GET /v2/users/123456789/roles

# Get user roles scoped to account
accsvc GET "/v2/users/123456789/roles?accountKey=6472352565130037257"

# Get user settings for product
accsvc GET /v2/users/123456789/products/jive

# Get batch users
accsvc GET "/v2/users/123,456,789?batch=true"

# Get user account memberships
accsvc GET "/v2/users/123456789/accounts?ids=true"

# Scan users by domain
accsvc GET "/v2/users?domain=example.com&count=50"
```

## Notes

- User keys are 64-bit integers
- Filtering supports SCIM-like expressions (eq, sw, co, etc.)
- Pagination uses 1-based startIndex
- Maximum count is typically 100 for most operations
- Settings inheritance can be controlled with `inherit` parameter
- Deleted users require `includeDeleted=true` parameter

## Schema & Custom Attributes

**Users have an extendable schema** - they can have custom attributes beyond the standard schema.

**Standard attributes**: `key`, `email`, `firstname`, `lastname`, `createtime`, `locale`, `timezone`, `status`, `password`, `residencyregion`, etc.

**Custom attributes**: Users can have ANY custom attribute (max 64 char name). Query them using scan operations:
```bash
# Example: Query by custom "department" attribute
accsvc GET "/v2/users?name=department&value=\"Engineering\"&count=50"

# Example: Query by custom "title" attribute in account context
accsvc GET "/v2/accounts/123/users?name=title&value=\"Engineer\"&count=50"

# Example: Query by custom "employeeId" attribute
accsvc GET "/v2/users?name=employeeId&value=\"EMP-12345\"&count=10"
```

**Filter expressions** support standard attributes only:
```bash
# Standard attributes work with filter
accsvc GET "/v2/accounts/123/users?filter=firstName+eq+\"John\""
accsvc GET "/v2/accounts/123/users?filter=email+co+\"@acme.com\""
```

**Product settings are schemaless** - `/users/{key}/products/{productName}` can contain any JSON structure.

See `schemas.md` for complete user schema documentation.
