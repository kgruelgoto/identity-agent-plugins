---
name: java-ticket-generator
description: Generate complete Java ticket implementations for as-ofs-tools from Jira requirements or user specifications. Use when creating new Java ticket files that follow established codebase patterns for SKU management, role updates, and pipeline operations.
---

# Java Ticket Generator
Generates complete Java ticket implementation code following established patterns in the as-ofs-tools codebase.

For examples, see [examples.md](./examples.md).
For reference guide, see [reference.md](./reference.md).

## When to use this skill
- When creating new Java ticket implementations from Jira requirements
- When you have specific SKU operations that need to be implemented
- When you need to follow established patterns for role updates, child SKU management, or complex operations
- When converting manual requirements into standardized Java ticket code

## What this skill will do
1. Parse ticket requirements (SKU names, operations, roles, child relationships)
2. Select appropriate implementation pattern (simple UpdateSkuStage, function-based, or complex CreateOrUpdateSkuStage)
3. Generate complete Java class with proper imports, error handling, and pipeline setup
4. Follow naming conventions and structural patterns from existing tickets
5. Include standard environment setup and UploadSkus integration

Generate a complete Java ticket implementation with:
- Proper class structure and imports
- Appropriate builder patterns (UpdateSkuBuilder, CreateSkuBuilder)
- Correct pipeline configuration with channels and stages
- Standard error handling and argument validation
- Environment setup following established patterns

Provide the requirements including:
- Ticket number (for class naming)
- Target SKU names
- Operations needed (role updates, child SKU changes, etc.)
- Any special requirements (trial settings, entitlements, etc.)

## Jira Integration

When invoked with a Jira ticket number:
- Use: `/java-ticket-generator IAMTASKS-1999`
- Fetches ticket via: `jira issue view TICKET-ID --plain`
- Parses description for requirements
- Detects operation type from keywords
- Generates complete implementation

## Pattern Detection

**SKU Creation Keywords** (use CreateOrUpdateSkuStage):
- "Create new", "new SKU", "new license", "new OFS Template"
- "BOSS template", "JIVE template"
- SKU names in bold or specific format

**License Sweep Keywords** (add license scanning stages):
- "update existing", "apply to existing accounts", "sweep licenses"
- "scan licenses", "update accounts"

**Base Template Detection**:
- "copy of X", "based on X", "similar to X"
- Extract template name for entitlement copying

**Role Update Keywords** (use UpdateSkuStage):
- "add role", "update role", "remove role"
- Role names explicitly mentioned

## Ticket Validation (CRITICAL)

Before generating code, validate the ticket requirements:

**FALSE Value Anti-Pattern:**
- If a ticket requests adding an attribute with `false` value, STOP and question this
- False values are stop conditions - they don't enable features
- Example: "add attribute blockpstn with default false" → This is likely incorrect
- Clarify with user: Should this be true? Or is this a negative capability flag?
- Exception: If the attribute is explicitly a negative flag (like "blockfeature") where false means enabled

**File Naming Convention:**
- Ticket class name: `IAM<number>.java` (e.g., `IAM1999.java`)
- Strip "TASKS" or other prefixes from ticket number
- IAMTASKS-1999 → IAM1999.java
- IAM-2152 → IAM2152.java

## Generation Flow for SKU Creation

When creating new SKUs (detected via keywords):

1. Extract from Jira:
   - SKU names (e.g., "G2CInternalOnlyL", "G2CInternalOnlyU")
   - Product (e.g., "g2c", "gotoresolve")
   - Base template to copy (e.g., "G2CLowUsage")
   - License/SKU entitlements
   - Whether add-on or standalone
   - Roles required

2. **VALIDATE REQUIREMENTS** (see Ticket Validation section above)
   - Check for false value anti-pattern
   - Confirm attribute naming and purpose
   - Verify ticket number format

3. Determine pipeline stages:
   - CreateOrUpdateSkuStage for new/updated SKUs
   - If "existing licenses" mentioned: InjectOnCloseStage + PartitionStage + ScanLicensesByAttrStage
   - UpdateLicenseEntsStage or UpdateLicenseAttrsStage for license updates
   - RunOnCloseStage with UploadSkus

4. Generate complete Java class with proper pattern
   - Use IAM<number> for class name
   - Strip TASKS or other prefixes from ticket number
