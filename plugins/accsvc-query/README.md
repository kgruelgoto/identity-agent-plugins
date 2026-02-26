# Account Service Query Plugin

Query the Account Service API for read-only operations across dev, stage, and live environments.

## Overview

This plugin provides two ways to interact with the Account Service API:

1. **CLI Tool** (`accsvc`): Direct command-line access for developers
2. **Claude Skill**: Natural language queries via Claude Code

Both interfaces support querying accounts, users, organizations, and licenses across ED1 (development), stage, and live environments.

## Features

- ✅ Read-only GET operations (safe by design)
- ✅ Multi-environment support (ED1, stage, live)
- ✅ Simple authentication via environment variables
- ✅ Natural language queries via Claude Code
- ✅ Comprehensive endpoint documentation
- ✅ Batch operations support
- ✅ JSON response processing with jq

## Installation

### Prerequisites

- `curl` command-line tool
- `jq` for JSON processing (optional but recommended)
- Valid Account Service client credentials

### Setup

1. **Install the plugin** via Claude Code marketplace or manually place in your plugins directory

2. **Set up credentials** by adding to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

   **Option A: Single credentials for all environments**
   ```bash
   export ACCSVC_CLIENT_NAME="your_client_name"
   export ACCSVC_CLIENT_SECRET="your_client_secret"
   ```

   **Option B: Environment-specific credentials** (recommended if credentials differ)
   ```bash
   # ED1 (development)
   export ACCSVC_ED1_CLIENT_NAME="your_ed1_client_name"
   export ACCSVC_ED1_CLIENT_SECRET="your_ed1_client_secret"

   # Stage
   export ACCSVC_STAGE_CLIENT_NAME="your_stage_client_name"
   export ACCSVC_STAGE_CLIENT_SECRET="your_stage_client_secret"

   # Live (production)
   export ACCSVC_LIVE_CLIENT_NAME="your_live_client_name"
   export ACCSVC_LIVE_CLIENT_SECRET="your_live_client_secret"
   ```

   **Option C: Mix both** (environment-specific overrides defaults)
   ```bash
   # Default for ED1 and Stage
   export ACCSVC_CLIENT_NAME="your_dev_client_name"
   export ACCSVC_CLIENT_SECRET="your_dev_client_secret"

   # Override for Live only
   export ACCSVC_LIVE_CLIENT_NAME="your_prod_client_name"
   export ACCSVC_LIVE_CLIENT_SECRET="your_prod_client_secret"
   ```

3. **Reload your shell**:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

4. **Verify setup**:
   ```bash
   accsvc --help
   ```

## Usage

### CLI Tool

The `accsvc` command provides direct API access:

```bash
# Basic syntax
accsvc GET <path> [--env <environment>]

# Get an account (uses ED1 by default)
accsvc GET /v2/accounts/6472352565130037257

# Get user by key
accsvc GET /v2/users/123456789

# Query stage environment
accsvc GET /v2/accounts/6472352565130037257 --env stage

# Query production (use with caution)
accsvc GET /v2/accounts/6472352565130037257 --env live

# Pipe to jq for pretty printing
accsvc GET /v2/accounts/6472352565130037257 | jq .

# Extract specific fields
accsvc GET /v2/users/123456789 | jq -r '.email'
```

**Available environments**:
- `ed1` (default) - Development environment
- `stage` - Staging environment
- `live` - Production environment

### Natural Language with Claude Code

Ask Claude questions about Account Service data:

```
Get account 6472352565130037257

Show me the products for that account

Get the jive settings for account 6472352565130037257

Find all users in account 6472352565130037257

Get the list of user emails that have the license Jive Standalone for that account

Show me user 123456789 from stage
```

Claude will:
1. Understand your question
2. Look up the appropriate API endpoints
3. Execute the queries using `accsvc`
4. Format the results for you

## Endpoints

The plugin supports GET operations for:

### Accounts (9 operations)
- Get account by key
- Find accounts with filters
- Get account plans, products, settings
- Batch get multiple accounts
- Scan by attributes or parent key

### Users (29 operations)
- Get user by key or email
- Find users with filters and pagination
- Get user roles, settings, products
- Get account/organization users
- Scan users by domain, attribute, or key
- User-account and user-license relationships

### Organizations (5 operations)
- Get organization by key
- Find organizations by filter, domains, users, or client ID
- Organization users, domains, and clients

### Licenses (12 operations)
- Get license by key
- Get licenses for accounts or users
- Get license users, products, entitlements
- Find and scan licenses by attribute or role
- Batch license operations

See `skills/accsvc-query/endpoints-*.md` for complete API reference.

## Examples

### Simple Queries

```bash
# Get account information
accsvc GET /v2/accounts/6472352565130037257

# Get user by email
accsvc GET "/v2/users?email=user@example.com"

# Get licenses for account
accsvc GET /v2/accounts/6472352565130037257/licenses

# Get users in account
accsvc GET "/v2/accounts/6472352565130037257/users?ids=false"
```

### Advanced Queries

```bash
# Find accounts by name pattern
accsvc GET "/v2/accounts?filter=name=Acme*&maxResults=10"

# Get user roles scoped to account
accsvc GET "/v2/users/123456789/roles?accountKey=6472352565130037257"

# Get licenses with specific role
accsvc GET "/v2/accounts/6472352565130037257/licenses?roles=ROLE_G2M_ORGANIZER"

# Batch get multiple users
accsvc GET "/v2/users/123,456,789?batch=true"
```

### Multi-Step Queries

Get user emails for a specific license type:

```bash
# 1. Get account licenses
LICENSES=$(accsvc GET /v2/accounts/6472352565130037257/licenses)

# 2. Filter for specific license name
LICENSE_KEY=$(echo "$LICENSES" | jq -r '.[] | select(.name == "Jive Standalone") | .key')

# 3. Get user keys from license
USER_KEYS=$(accsvc GET /v2/licenses/$LICENSE_KEY/users | jq -r '.[]')

# 4. Get email for each user
for USER_KEY in $USER_KEYS; do
    accsvc GET /v2/users/$USER_KEY | jq -r '.email'
done
```

See `skills/accsvc-query/query-examples.md` for more patterns.

## Documentation

The plugin includes comprehensive documentation:

- **`skills/accsvc-query/endpoints-accounts.md`** - Account GET operations reference
- **`skills/accsvc-query/endpoints-users.md`** - User GET operations reference
- **`skills/accsvc-query/endpoints-organizations.md`** - Organization GET operations reference
- **`skills/accsvc-query/endpoints-licenses.md`** - License GET operations reference
- **`skills/accsvc-query/schemas.md`** - **Resource schemas and extendable attributes** ⭐
- **`skills/accsvc-query/environments.md`** - Environment URLs and safety guidelines
- **`skills/accsvc-query/query-examples.md`** - Common query patterns and examples
- **`skills/accsvc-query/SKILL.md`** - Claude skill instructions

### Extendable Schema

**Important**: All major resources (Account, User, License, Organization) have **extendable schemas** - they can have custom attributes beyond the documented schema. This means you can query by ANY attribute, not just the standard ones. See `schemas.md` for details.

## Safety

This plugin is designed with safety in mind:

- ✅ **Read-only**: Only GET operations are supported (no modifications possible)
- ✅ **Default to dev**: Queries use ED1 (development) by default
- ✅ **Environment isolation**: Each environment has separate data
- ✅ **Credential security**: Credentials stored in environment variables, never in code
- ✅ **Clear errors**: Helpful error messages for common issues

**Best Practices**:
- Always test queries in ED1 first
- Confirm before querying production (live)
- Use batch operations to reduce API load
- Filter on the server side (use query parameters)

## Troubleshooting

### Authentication Errors (401)

```bash
# Check if credentials are set
echo $ACCSVC_CLIENT_NAME
echo $ACCSVC_CLIENT_SECRET

# Check environment-specific credentials
echo $ACCSVC_ED1_CLIENT_NAME
echo $ACCSVC_STAGE_CLIENT_NAME
echo $ACCSVC_LIVE_CLIENT_NAME

# Set credentials (default for all environments)
export ACCSVC_CLIENT_NAME="your_client_name"
export ACCSVC_CLIENT_SECRET="your_client_secret"

# Or set environment-specific
export ACCSVC_STAGE_CLIENT_NAME="your_stage_client_name"
export ACCSVC_STAGE_CLIENT_SECRET="your_stage_client_secret"
```

**Credential Resolution Order**:
1. Environment-specific variables (e.g., `ACCSVC_STAGE_CLIENT_NAME`)
2. Falls back to generic variables (`ACCSVC_CLIENT_NAME`)
3. Error if neither is set

### Not Found Errors (404)

- Verify the resource key exists in the target environment
- Remember: keys are environment-specific (ED1 keys differ from stage/live)
- Check the endpoint path is correct (refer to endpoint documentation)

### Command Not Found

```bash
# Check if plugin bin directory is in PATH
which accsvc

# If not found, add plugin bin to PATH or use full path
/path/to/plugins/accsvc-query/bin/accsvc GET /v2/accounts/123
```

### Invalid JSON Response

- Check if the API returned an error (look at stderr output)
- Verify credentials are correct
- Ensure the endpoint path is valid

## Environment URLs

- **ED1**: `https://acc1ed1svc.qai.expertcity.com`
- **Stage**: `https://accstagesvc.iad.expertcity.com`
- **Live**: `https://accsvc.iad.expertcity.com`

## API Documentation

Full API documentation available at: https://iamdocs.serversdev.getgo.com/account/index.html

## Contributing

This plugin is maintained by the Identity Platform team. For questions or issues:

- Slack: #identity-platform
- Report bugs or request features via team channels

## Version

**Version**: 1.0.0

## License

Internal use only - GoTo Identity Platform Team

---

## Quick Reference

### Common Commands

```bash
# Get account
accsvc GET /v2/accounts/{accountKey}

# Get user by email
accsvc GET "/v2/users?email={email}"

# Get account users
accsvc GET "/v2/accounts/{accountKey}/users?ids=false"

# Get account licenses
accsvc GET /v2/accounts/{accountKey}/licenses

# Get license users
accsvc GET /v2/licenses/{licenseKey}/users

# Get organizations by domain
accsvc GET "/v2/organizations?domains={domain}"

# Use different environment
accsvc GET /v2/accounts/{accountKey} --env stage
```

### jq Quick Tips

```bash
# Pretty print
accsvc GET /v2/accounts/123 | jq .

# Extract field
accsvc GET /v2/users/123 | jq -r '.email'

# Filter array
accsvc GET /v2/accounts/123/licenses | jq '.[] | select(.enabled == true)'

# Count results
accsvc GET /v2/accounts/123/licenses | jq 'length'

# Multiple fields
accsvc GET /v2/users/123 | jq '{email: .email, key: .key}'

# Array of values
accsvc GET /v2/accounts/123/licenses | jq -r '.[].key'
```
