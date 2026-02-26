# Environments

The Account Service is deployed in three environments. Each environment has its own base URL and data.

## Environment URLs

### ED1 (Development)
- **URL**: `https://acc1ed1svc.qai.expertcity.com`
- **Purpose**: Development and testing
- **Safety**: **Default environment** - safest for experimentation
- **Data**: Test accounts and users for development purposes

### Stage (Staging)
- **URL**: `https://accstagesvc.iad.expertcity.com`
- **Purpose**: Pre-production testing
- **Safety**: Intermediate - contains staging data
- **Data**: Staging accounts and users, may mirror production structure

### Live (Production)
- **URL**: `https://accsvc.iad.expertcity.com`
- **Purpose**: Production environment
- **Safety**: **Use with caution** - production data
- **Data**: Real customer accounts and users

## Authentication

All environments require authentication via client credentials.

### Credential Configuration

**Option 1: Single credentials for all environments**
```bash
export ACCSVC_CLIENT_NAME="your_client_name"
export ACCSVC_CLIENT_SECRET="your_client_secret"
```

**Option 2: Environment-specific credentials** (recommended if credentials differ)
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

### Credential Resolution

The `accsvc` tool uses this order to find credentials:
1. **Environment-specific** variables (e.g., `ACCSVC_STAGE_CLIENT_NAME` for stage)
2. **Generic** variables (`ACCSVC_CLIENT_NAME`) as fallback
3. **Error** if neither is set

This allows you to:
- Use the same credentials everywhere (set generic variables only)
- Use different credentials per environment (set environment-specific variables)
- Mix both (environment-specific overrides generic)

**Headers** (automatically added by `accsvc` CLI):
- `ClientName: <resolved_client_name>`
- `ClientSecret: <resolved_client_secret>`

## Safety Guidelines

1. **Default to ED1**: Unless specifically asked to query stage or live, always use ED1 (the default)
2. **Confirm for Live**: When querying production (live), confirm with the user first
3. **Read-Only**: All operations through this plugin are GET (read-only) to prevent accidental modifications
4. **Credentials**: Never log or display credential values

## Environment Selection

### CLI Tool
```bash
# Uses ED1 by default
accsvc GET /v2/accounts/123

# Specify environment explicitly
accsvc GET /v2/accounts/123 --env stage
accsvc GET /v2/accounts/123 --env live
```

### From Natural Language

When a user asks about data without specifying environment:
- **Default**: Use ED1
- **User specifies "stage" or "staging"**: Use `--env stage`
- **User specifies "live", "prod", or "production"**: Use `--env live`, but confirm first

**Examples**:
- "Get account 123" → Use ED1 (default)
- "Get account 123 from stage" → Use `--env stage`
- "Get account 123 in production" → Confirm with user, then use `--env live`
- "Get account 123 in ed" / "Get account 123 from ed1" → Use ED1 explicitly

## Environment-Specific Data

Each environment has separate databases with different data:
- Account keys, user keys, organization keys are environment-specific
- A key that exists in ED1 may not exist in stage or live
- When troubleshooting, ensure you're querying the correct environment

## API Consistency

All environments expose the same API endpoints and behavior. The only differences are:
- Base URL
- Data contained in the environment
- Potentially different service versions (live may lag behind stage)
