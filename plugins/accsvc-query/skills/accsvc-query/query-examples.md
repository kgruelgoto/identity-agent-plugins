# Query Examples

This document provides common query patterns and examples for using the Account Service Query Plugin.

## Single Resource Queries

### Get Account Information
```bash
# Basic account
accsvc GET /v2/accounts/6472352565130037257

# Account products
accsvc GET /v2/accounts/6472352565130037257/products

# Account plans
accsvc GET /v2/accounts/6472352565130037257/plans

# Account settings for specific product
accsvc GET /v2/accounts/6472352565130037257/products/jive
```

### Get User Information
```bash
# Basic user
accsvc GET /v2/users/123456789

# User by email
accsvc GET "/v2/users?email=user@example.com"

# User roles (with inheritance)
accsvc GET /v2/users/123456789/roles

# User roles scoped to account
accsvc GET "/v2/users/123456789/roles?accountKey=6472352565130037257"

# User account memberships
accsvc GET "/v2/users/123456789/accounts?ids=true"

# User products
accsvc GET /v2/users/123456789/products
```

### Get Organization Information
```bash
# Basic organization
accsvc GET /v2/organizations/123456789

# Find by domain
accsvc GET "/v2/organizations?domains=acme.com"

# Find by user
accsvc GET "/v2/organizations?userKeys=123456789"
```

### Get License Information
```bash
# Basic license
accsvc GET /v2/licenses/123456789

# License users
accsvc GET /v2/licenses/123456789/users

# License products
accsvc GET /v2/licenses/123456789/products

# License entitlements for product
accsvc GET /v2/licenses/123456789/products/jive
```

## Multi-Step Queries

### Get Users with Specific License Type

**Goal**: Find all users in an account who have a specific license (e.g., "Jive Standalone").

**Steps**:
1. Get all licenses for the account
2. Filter for licenses matching the name
3. For each matching license, get the user keys
4. For each user key, get the user details
5. Extract email addresses

**Example**:
```bash
# Step 1: Get account licenses
LICENSES=$(accsvc GET /v2/accounts/6472352565130037257/licenses)

# Step 2: Filter for "Jive Standalone" (use jq)
LICENSE_KEYS=$(echo "$LICENSES" | jq -r '.[] | select(.name == "Jive Standalone") | .key')

# Step 3: For each license, get users
for LICENSE_KEY in $LICENSE_KEYS; do
    USER_KEYS=$(accsvc GET /v2/licenses/$LICENSE_KEY/users | jq -r '.[]')

    # Step 4: Get user details and extract emails
    for USER_KEY in $USER_KEYS; do
        accsvc GET /v2/users/$USER_KEY | jq -r '.email'
    done
done
```

### Get All User Emails in Account

**Goal**: List all email addresses for users in an account.

**Steps**:
1. Get user keys for the account
2. Batch fetch users (up to 40 at a time)
3. Extract email addresses

**Example**:
```bash
# Step 1: Get user keys
USER_KEYS=$(accsvc GET "/v2/accounts/6472352565130037257/users?ids=true" | jq -r '.[]' | tr '\n' ',')

# Step 2: Batch get users (handle batching if >40 users)
accsvc GET "/v2/users/${USER_KEYS}?batch=true" | jq -r '.[].email'
```

### Get Settings for Multiple Accounts

**Goal**: Compare settings for a specific product across multiple accounts.

**Steps**:
1. Use batch settings endpoint with comma-separated account keys

**Example**:
```bash
# Get jive settings for multiple accounts
accsvc GET "/v2/accounts/123,456,789/products/jive?batch=true&inherit=true"
```

### Find Accounts by User Email

**Goal**: Find which accounts a user belongs to, starting from their email.

**Steps**:
1. Get user by email
2. Extract user key
3. Get account keys for user
4. Batch get account details

**Example**:
```bash
# Step 1-2: Get user and extract key
USER_KEY=$(accsvc GET "/v2/users?email=user@example.com" | jq -r '.key')

# Step 3: Get account keys
ACCOUNT_KEYS=$(accsvc GET "/v2/users/$USER_KEY/accounts?ids=true" | jq -r '.[]' | tr '\n' ',')

# Step 4: Get account details
accsvc GET "/v2/accounts/${ACCOUNT_KEYS}?batch=true"
```

## Filtering and Searching

### Find Accounts by Name Pattern
```bash
# Wildcard search
accsvc GET "/v2/accounts?filter=name=Acme*&maxResults=20"

# Exact match
accsvc GET "/v2/accounts?filter=name=Acme+Inc&maxResults=20"
```

### Find Users in Account with Filter
```bash
# Users with first name "John"
accsvc GET "/v2/accounts/6472352565130037257/users?filter=firstName+eq+\"John\"&count=10"

# Users with email domain
accsvc GET "/v2/accounts/6472352565130037257/users?filter=email+co+\"@acme.com\"&count=10"

# Paginated results
accsvc GET "/v2/accounts/6472352565130037257/users?paginate=true&startIndex=1&count=100"
```

### Scan Users by Domain
```bash
# All users with @acme.com domain
accsvc GET "/v2/users?domain=acme.com&count=50"
```

### Find Licenses by Role
```bash
# All licenses with specific role
accsvc GET "/v2/accounts/6472352565130037257/licenses?roles=ROLE_G2M_ORGANIZER"

# Licenses with any of multiple roles
accsvc GET "/v2/accounts/6472352565130037257/licenses?roles=ROLE_G2M_ORGANIZER,ROLE_G2W_ORGANIZER"
```

## Using jq for JSON Processing

The `jq` tool is invaluable for processing JSON responses.

### Extract Specific Fields
```bash
# Get just the account name
accsvc GET /v2/accounts/123 | jq -r '.name'

# Get all user emails from account
accsvc GET "/v2/accounts/123/users?ids=false" | jq -r '.[].email'

# Get license seats and remaining
accsvc GET /v2/licenses/123 | jq '{seats: .seats, remaining: .remaining}'
```

### Filter Arrays
```bash
# Find licenses with remaining seats
accsvc GET /v2/accounts/123/licenses | jq '.[] | select(.remaining > 0)'

# Find enabled licenses only
accsvc GET /v2/accounts/123/licenses | jq '.[] | select(.enabled == true)'

# Find licenses with specific role
accsvc GET /v2/accounts/123/licenses | jq '.[] | select(.roles[] | contains("ORGANIZER"))'
```

### Count Results
```bash
# Count users in account
accsvc GET "/v2/accounts/123/users?ids=true" | jq 'length'

# Count licenses with remaining seats
accsvc GET /v2/accounts/123/licenses | jq '[.[] | select(.remaining > 0)] | length'
```

### Format Output
```bash
# Pretty table of users
accsvc GET "/v2/accounts/123/users?ids=false" | jq -r '.[] | "\(.key)\t\(.email)\t\(.firstName) \(.lastName)"'

# CSV format
accsvc GET "/v2/accounts/123/users?ids=false" | jq -r '["key","email","name"], (.[] | [.key, .email, (.firstName + " " + .lastName)]) | @csv'
```

## Pagination Patterns

### Manual Pagination
```bash
# Page 1 (results 1-100)
accsvc GET "/v2/accounts/123/users?paginate=true&startIndex=1&count=100"

# Page 2 (results 101-200)
accsvc GET "/v2/accounts/123/users?paginate=true&startIndex=101&count=100"

# Page 3 (results 201-300)
accsvc GET "/v2/accounts/123/users?paginate=true&startIndex=201&count=100"
```

### Get All Results (Loop)
```bash
START_INDEX=1
COUNT=100
while true; do
    RESPONSE=$(accsvc GET "/v2/accounts/123/users?paginate=true&startIndex=$START_INDEX&count=$COUNT")
    RESULTS=$(echo "$RESPONSE" | jq '.resources')

    if [ "$(echo "$RESULTS" | jq 'length')" -eq 0 ]; then
        break
    fi

    echo "$RESULTS" | jq -r '.[].email'

    START_INDEX=$((START_INDEX + COUNT))
done
```

## Error Handling

### Check HTTP Status
```bash
# Using curl directly to check status
HTTP_CODE=$(curl -s -w "%{http_code}" -o response.json \
    -H "ClientName: $ACCSVC_CLIENT_NAME" \
    -H "ClientSecret: $ACCSVC_CLIENT_SECRET" \
    "https://acc1ed1svc.qai.expertcity.com/v2/accounts/123")

if [ "$HTTP_CODE" -eq 200 ]; then
    cat response.json | jq .
elif [ "$HTTP_CODE" -eq 404 ]; then
    echo "Resource not found"
else
    echo "Error: HTTP $HTTP_CODE"
    cat response.json
fi
```

### Validate Response
```bash
# Check if response is valid JSON
RESPONSE=$(accsvc GET /v2/accounts/123)
if echo "$RESPONSE" | jq empty 2>/dev/null; then
    echo "Valid JSON response"
    echo "$RESPONSE" | jq .
else
    echo "Invalid JSON response:"
    echo "$RESPONSE"
fi
```

## Tips and Best Practices

1. **Use Batch Operations**: When fetching multiple resources, use batch endpoints to reduce API calls
   - `/users/{keys}?batch=true` instead of multiple `/users/{key}` calls

2. **Filter Early**: Use query parameters to filter on the server side instead of fetching everything and filtering locally
   - `?filter=name=Acme*` instead of fetching all and grepping

3. **Limit Results**: Use `count` or `maxResults` parameters to avoid large responses
   - `?count=10` for exploratory queries

4. **URL Encode**: Remember to URL encode query parameters
   - Space → `+` or `%20`
   - `"` → `%22`
   - Use bash quoting: `accsvc GET "/v2/users?email=user@example.com"`

5. **Pipe to jq**: Always pipe JSON responses to `jq` for readability
   - `accsvc GET /v2/accounts/123 | jq .`

6. **Save Responses**: For complex queries, save intermediate responses
   - `accsvc GET /v2/accounts/123/licenses > licenses.json`

7. **Check Docs**: Refer to endpoint reference docs for available parameters and response structures
   - `endpoints-accounts.md`, `endpoints-users.md`, etc.
