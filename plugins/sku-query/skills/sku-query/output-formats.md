# Output Formatting Guidelines

Structure your responses based on the query type to provide clear, actionable information.

## Format 1: Feature/Permission Queries

**Use when**: User asks "Which SKUs have [feature]?" or "Show me SKUs with [permission]"

```markdown
## SKUs with [feature/permission]

**Found N SKUs:**

1. **[SKU-NAME]** - [Description]
   - Product: [product]
   - [Relevant entitlement details]

2. **[SKU-NAME]** - [Description]
   - Product: [product]
   - [Relevant entitlement details]

...
```

**Example**:
```markdown
## SKUs with Transcription (License Level)

**Found 3 SKUs:**

1. **G2WPROU** - GoTo Webinar Pro Unlimited
   - Product: g2w
   - License Entitlement: transcriptsprovisioned = true

2. **G2WBIZU** - GoTo Webinar Business Unlimited
   - Product: g2w
   - License Entitlement: transcriptsprovisioned = true
```

## Format 2: Validation Queries

**Use when**: User asks to validate specific SKUs or check if SKUs have certain properties

```markdown
## SKU Validation Results

**SKU: [NAME]**
- Product: [product]
- License Entitlements: [present/absent]
  - [list if present]
- Account Entitlements: [present/absent]
  - [list if present]

**Analysis**: [What this means for the change being validated]
```

**Example**:
```markdown
## SKU Validation Results

**SKU: G2CCXAU**
- Product: jive
- License Entitlements: Present
  - advancedivrprovisioned: true
  - e911provisioned: true
- Account Entitlements: Present
  - maxcallqueues: 25
  - advancedreportingallowed: true

**Analysis**: This SKU has both license and account level entitlements, making it suitable for the proposed feature change.
```

## Format 3: Comparison Queries

**Use when**: User asks to compare multiple SKUs or show differences

```markdown
## SKU Comparison

| SKU | Product | License Entitlements | Account Entitlements |
|-----|---------|---------------------|---------------------|
| ... | ...     | ...                 | ...                 |

**Key Differences**: [highlight important distinctions]
```

**Example**:
```markdown
## SKU Comparison

| SKU | Product | transcriptsprovisioned (License) | transcriptionallowed (Account) |
|-----|---------|----------------------------------|-------------------------------|
| G2WPROU | g2w | true | true |
| G2WSTDU | g2w | false | false |

**Key Differences**: The Pro Unlimited SKU provides transcription at both the license and account level, while Standard does not include transcription capabilities.
```

## Format 4: Detailed SKU Information

**Use when**: User asks for complete information about a specific SKU

```markdown
## SKU Details: [SKU-NAME]

**Basic Information:**
- Name: [description]
- Product: [product]
- Unlimited: [true/false]

**License Attributes:**
- [key]: [value]
- [key]: [value]

**License Entitlements:**
Product: [product-name]
- [feature]: [value]
- [feature]: [value]

**Account Entitlements:**
Product: [product-name]
- [setting]: [value]
- [setting]: [value]

**Relationships:**
- Provides: [list]
- Requires: [list]
- Child SKUs: [list]
```

## Format 5: List Queries

**Use when**: User asks for a simple list of SKUs

```markdown
## [Product/Category] SKUs

**Found N SKUs:**

- **SKU-NAME** - Description
- **SKU-NAME** - Description
- **SKU-NAME** - Description
```

## Formatting Tips

1. **Use bold** for SKU names to make them stand out
2. **Include product names** for context
3. **Show actual values** from the data, not just "true" when possible
4. **Add analysis** to explain what the data means
5. **Keep it concise** - only show relevant fields
6. **Use tables** for side-by-side comparisons
7. **Group by product** when showing multiple products

## Special Cases

### When No Results Found

```markdown
## No SKUs Found

No SKUs matched the criteria: [describe what was searched for]

**Suggestions:**
- Check SKU name spelling
- Verify the feature/entitlement name
- Try searching in a different product family
```

### When Data Fetch Fails

```markdown
## Unable to Fetch SKU Data

Failed to retrieve SKU data from the live environment.

**Error**: [specific error message]

**Next Steps:**
- Verify network connectivity
- Check if the endpoint is accessible
- Try again in a few moments
```
