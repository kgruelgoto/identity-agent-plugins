---
name: accsvc-query
description: Query Account Service API to retrieve information about accounts, users, organizations, and licenses across different environments
allowed_tools: [Bash, Read, Grep]
---

# Account Service Query Skill

This skill enables you to query the Account Service API using natural language questions. You can retrieve information about accounts, users, organizations, and licenses across ED1 (dev), stage, and live environments.

## Purpose

Answer user questions about Account Service data by:
1. Understanding the natural language question
2. Determining required API endpoints
3. Executing queries using the `accsvc` CLI tool
4. Processing JSON responses
5. Formatting answers for the user

## Available Tools

You have access to:
- **Bash**: Execute `accsvc` CLI commands and process responses with `jq`
- **Read**: Read endpoint reference documentation
- **Grep**: Search reference docs for specific endpoints

## Core Process

When the user asks a question about Account Service data:

### 1. Parse the Question
Identify:
- **Resource type**: Account, user, organization, or license?
- **Operation**: Get single resource, search, list, get related resources?
- **Environment**: ED1 (default), stage, or live?
- **Identifiers**: Keys, email addresses, names, etc.

### 2. Determine Endpoints
Use the endpoint reference documents to find the right API paths:
- **accounts**: Read `endpoints-accounts.md`
- **users**: Read `endpoints-users.md`
- **organizations**: Read `endpoints-organizations.md`
- **licenses**: Read `endpoints-licenses.md`

Search for operations by name or scan the document structure.

### 3. Execute Queries
Use the `accsvc` CLI tool via Bash:

```bash
# Basic syntax
accsvc GET <path> [--env <environment>]

# Examples
accsvc GET /v2/accounts/6472352565130037257
accsvc GET /v2/users/123456789
accsvc GET /v2/accounts/123/licenses --env stage
```

**Environment Selection**:
- Default: ED1 (safest, for development)
- Stage: Use when user mentions "stage" or "staging"
- Live: Use when user mentions "live" or "production" (confirm first!)

### 4. Process Responses
Use `jq` to parse and extract data from JSON responses:

```bash
# Extract specific field
accsvc GET /v2/users/123 | jq -r '.email'

# Filter arrays
accsvc GET /v2/accounts/123/licenses | jq '.[] | select(.remaining > 0)'

# Extract multiple fields
accsvc GET /v2/users/123 | jq '{email: .email, name: (.firstName + " " + .lastName)}'
```

### 5. Handle Multi-Step Queries
Some questions require multiple API calls:

**Example: "Get users with Jive Standalone license in account X"**
1. Get licenses for account: `GET /v2/accounts/{accountKey}/licenses`
2. Filter for "Jive Standalone" license using jq
3. For each matching license, get users: `GET /v2/licenses/{licenseKey}/users`
4. For each user key, get user details: `GET /v2/users/{userKey}`
5. Extract and list email addresses

See `query-examples.md` for more multi-step patterns.

## Reference Documents

**ALWAYS read the relevant reference document when determining endpoints**:

- `endpoints-accounts.md` - 9 GET operations for accounts, plans, products, settings
- `endpoints-users.md` - 29 GET operations for users, roles, settings, scanning
- `endpoints-organizations.md` - 5 GET operations for organizations, domains, users, clients
- `endpoints-licenses.md` - 12 GET operations for licenses, users, products, entitlements
- `schemas.md` - **Resource schemas and extendable attributes** ⭐
- `environments.md` - Environment URLs and safety guidelines
- `query-examples.md` - Common query patterns and jq examples

### Important: Extendable Schema

**All major resources (Account, User, License, Organization) have extendable schemas**, meaning they can have custom attributes beyond the documented schema. When a user asks about filtering or querying by a specific attribute:

1. Check if it's a standard attribute in `schemas.md`
2. If not standard, it might be a custom attribute - you can still query it using "scan by attribute" endpoints
3. Custom attribute names are limited to 64 characters
4. Product settings (`/resources/{key}/products/{productName}`) are completely schemaless

**Example**: "Find users with department=Engineering" → Even though "department" isn't in the standard schema, you can query it:
```bash
accsvc GET "/v2/users?name=department&value=\"Engineering\"&count=50"
```

## Common Query Patterns

### Single Resource by Key
```bash
# Account
accsvc GET /v2/accounts/{accountKey}

# User
accsvc GET /v2/users/{userKey}

# Organization
accsvc GET /v2/organizations/{organizationKey}

# License
accsvc GET /v2/licenses/{licenseKey}
```

### Resource by Identifier (not key)
```bash
# User by email
accsvc GET "/v2/users?email={email}"

# Organizations by domain
accsvc GET "/v2/organizations?domains={domain}"
```

### Related Resources
```bash
# Users in account
accsvc GET "/v2/accounts/{accountKey}/users?ids=false"

# Licenses for account
accsvc GET /v2/accounts/{accountKey}/licenses

# User's account memberships
accsvc GET "/v2/users/{userKey}/accounts?ids=true"

# License users
accsvc GET /v2/licenses/{licenseKey}/users
```

### Settings and Products
```bash
# Account settings for product
accsvc GET /v2/accounts/{accountKey}/products/{productName}

# User settings for product
accsvc GET /v2/users/{userKey}/products/{productName}

# License entitlements
accsvc GET /v2/licenses/{licenseKey}/products/{productName}
```

### Batch Operations
```bash
# Multiple accounts
accsvc GET "/v2/accounts/{key1},{key2},{key3}?batch=true"

# Multiple users
accsvc GET "/v2/users/{key1},{key2},{key3}?batch=true"

# Multiple licenses
accsvc GET "/v2/licenses/{key1},{key2},{key3}?batch=true"
```

### Searching and Filtering
```bash
# Find accounts by name
accsvc GET "/v2/accounts?filter=name=Acme*&maxResults=10"

# Find users in account with filter
accsvc GET "/v2/accounts/{accountKey}/users?filter=firstName+eq+\"John\"&count=10"

# Find licenses with role filter
accsvc GET "/v2/accounts/{accountKey}/licenses?roles=ROLE_G2M_ORGANIZER"
```

## Response Formatting

When presenting answers to the user:

1. **Direct Answers**: If asking for a specific value (email, name, count), give the direct answer
   - "The email is user@example.com"
   - "There are 42 users in this account"

2. **Lists**: Format lists cleanly
   - Use bullets or numbered lists
   - Include relevant details (not just IDs)

3. **Complex Objects**: Show key fields, not entire JSON
   - For accounts: name, key, createTime
   - For users: email, firstName, lastName, key
   - For licenses: name, seats, remaining, enabled

4. **Large Results**: Summarize if there are many results
   - "Found 147 users. Here are the first 10:"
   - "The account has 23 licenses. The enabled ones are:"

## Error Handling

Handle common errors gracefully:

- **404 Not Found**: "Resource not found with that key/identifier"
- **401 Unauthorized**: "Authentication failed. Check credentials."
- **400 Bad Request**: "Invalid request. Check parameters."
- **Empty Results**: "No results found matching the criteria"

If a query fails, explain what went wrong and suggest alternatives.

## Safety Guidelines

1. **Default to ED1**: Unless explicitly asked for stage/live, always use ED1
2. **Confirm Production**: If user asks about "live" or "production", confirm before querying
3. **Read-Only**: All operations are GET (read-only) - you cannot modify data
4. **No Credentials**: Never display or log `ACCSVC_CLIENT_NAME` or `ACCSVC_CLIENT_SECRET` values

## Examples

### Example 1: Simple Account Query
**User**: "Get account 6472352565130037257"

**Process**:
1. Identify: Account resource, get by key, default to ED1
2. Read `endpoints-accounts.md` to find: `GET /accounts/{accountKey}`
3. Execute: `accsvc GET /v2/accounts/6472352565130037257`
4. Format response with key fields

### Example 2: Product Settings
**User**: "Get the jive settings for account 6472352565130037257"

**Process**:
1. Identify: Account settings, specific product (jive), default to ED1
2. Read `endpoints-accounts.md` to find: `GET /accounts/{accountKey}/products/{productName}`
3. Execute: `accsvc GET /v2/accounts/6472352565130037257/products/jive`
4. Format settings object

### Example 3: Multi-Step Query
**User**: "Get the list of user emails that have the license Jive Standalone for account 6472352565130037257"

**Process**:
1. Identify: Multi-step query (licenses → users → emails)
2. Read `endpoints-licenses.md` and `endpoints-users.md`
3. Execute:
   ```bash
   # Get licenses
   LICENSES=$(accsvc GET /v2/accounts/6472352565130037257/licenses)

   # Filter for Jive Standalone
   LICENSE_KEY=$(echo "$LICENSES" | jq -r '.[] | select(.name == "Jive Standalone") | .key')

   # Get users for license
   USER_KEYS=$(accsvc GET /v2/licenses/$LICENSE_KEY/users | jq -r '.[]')

   # Get emails
   for USER_KEY in $USER_KEYS; do
       accsvc GET /v2/users/$USER_KEY | jq -r '.email'
   done
   ```
4. List email addresses

### Example 4: Environment-Specific Query
**User**: "Get user 123456789 from stage"

**Process**:
1. Identify: User resource, get by key, STAGE environment
2. Read `endpoints-users.md` to find: `GET /users/{userKey}`
3. Execute: `accsvc GET /v2/users/123456789 --env stage`
4. Format response

## Tips

- **Read docs first**: Always check the endpoint reference docs to find the right API path
- **Use jq**: Pipe responses through jq for readable output and data extraction
- **Check examples**: Refer to `query-examples.md` for complex query patterns
- **Batch when possible**: Use batch endpoints to reduce API calls
- **Filter server-side**: Use query parameters to filter on the server instead of fetching everything
- **Test in ED1**: When unsure, test queries in ED1 first before running in stage/live

## Debugging

If a query fails:
1. Check the endpoint path is correct (read the reference docs)
2. Verify the resource key/identifier is valid
3. Check environment (ED1, stage, live)
4. Ensure credentials are set (`ACCSVC_CLIENT_NAME`, `ACCSVC_CLIENT_SECRET`)
5. Look at HTTP status code for clues (404 = not found, 401 = auth failed, etc.)
