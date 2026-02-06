# Ticket Creation Documentation Guide Skill

This skill provides comprehensive step-by-step guidance for manually creating Java ticket implementations in the as-ofs-tools codebase.

## Usage

This skill helps you:
1. Choose the right implementation pattern for your requirements
2. Follow established naming conventions and structure
3. Understand when to use different stages and builders
4. Implement proper error handling and pipeline setup

## Decision Tree: Pattern Selection

### Simple Updates (Same Change to All SKUs)
**When to use:**
- Applying identical change to 1-5 SKUs
- Single type of operation (add role, modify settings)
- All SKUs need exactly the same update

**Template:**
```java
public class IAM#### {
    public static void main(String[] args) throws InterruptedException {
        // Standard setup
        var skuNames = List.of("Sku1", "Sku2", "Sku3");
        var updateSku = new UpdateSkuBuilder()./* changes */.build();

        // Simple pipeline
        pipeline.add(new UpdateSkuStage(input, output, fs, updateSku));
    }
}
```

### Function-Based Updates (Different Changes Per SKU)
**When to use:**
- 1-5 SKUs with different operations per SKU
- Some SKUs need role changes, others need child SKU modifications
- Per-SKU customization needed

**Template:**
```java
public class IAM#### {
    public static void main(String[] args) throws InterruptedException {
        // Standard setup
        var skuNames = List.of("Sku1", "Sku2", "Sku3");

        Function<String, UpdateSkuRequest> updateFunction = skuName ->
            switch (skuName) {
                case "Sku1" -> new UpdateSkuBuilder()
                    .withRoles(rolesSet)
                    .withChildSkus(Optional.empty())
                    .withLicenseAttributes(true)
                    .build();
                case "Sku2", "Sku3" -> new UpdateSkuBuilder()
                    .withRoles(rolesSet)
                    .withLicenseAttributes(true)
                    .build();
                default -> throw new IllegalArgumentException("Unknown SKU: " + skuName);
            };

        // Function-based pipeline
        pipeline.add(new UpdateSkuStage(input, output, fs, updateFunction, false));
    }
}
```

### Complex Templates (Follow IAM1984 Pattern)
**When to use:**
- Many SKUs (5+ with different configurations)
- Multiple operations (create + update)
- Different SKU types need different templates
- Complex entitlements or trial settings

**Template:**
```java
public class IAM#### {
    public static void main(String[] args) throws InterruptedException {
        // Multiple templates
        var createBase = new CreateSkuBuilder()./* config */.build();
        var createTrial = new CreateSkuBuilder()./* trial config */.build();
        var updateBase = new UpdateSkuBuilder()./* updates */.build();

        // Complex pipeline with function mapping
        pipeline.add(new CreateOrUpdateSkuStage(input, output, fs,
            createFunction, updateFunction));
    }
}
```

## Step-by-Step Implementation Guide

### Step 1: Set Up Basic Structure

```java
package com.getgo.identity.tickets;

// Required imports (customize based on your needs)
import com.getgo.identity.channel.Channel;
import com.getgo.identity.channel.Pipeline;
import com.getgo.identity.channel.RunOnCloseStage;
import com.getgo.identity.channel.SeedStage;
import com.getgo.identity.environment.Environment;
import com.getgo.identity.environment.Kms;
import com.getgo.identity.stage.UpdateSkuStage;           // Simple & function-based updates
import com.getgo.identity.stage.CreateOrUpdateSkuStage;  // Complex operations
import com.getgo.identity.tools.UploadSkus;
import com.getgo.ofs.domain.UpdateSkuBuilder;
import com.getgo.ofs.domain.UpdateSkuRequest;            // For function-based updates
import com.getgo.ofs.domain.CreateSkuBuilder;            // If creating new SKUs

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.Optional;                               // For child SKUs
import java.util.Map;                                   // For entitlements
import java.util.function.Function;                      // For function-based patterns

public class IAM#### {
    public static void main(String[] args) throws InterruptedException {
        // Always include argument validation
        if (args.length != 1) {
            System.out.println("1 argument required: [environment]");
            return;
        }

        // Standard environment setup
        var env = Environment.environment(args[0], new Kms());
        var auth = env.authorizationService();
        var tokenTask = env.clientTokenManagerTask(auth);
        var fs = env.fulfillmentService(tokenTask);

        // Your implementation here...
    }
}
```

### Step 2: Define Your SKUs and Operations

**For Simple Updates:**
```java
// List target SKUs
var skuNames = List.of("ResolveMSPLaunch", "ResolveStarter", "ResolveAdvanced");

// Define the update
var updateSku = new UpdateSkuBuilder()
    .withRoles(Set.of("ROLE_GOTORESOLVE_ORGANIZER", "ROLE_GOTORESOLVE_MOBILE_ORGANIZER"))
    .withLicenseAttributes(true)  // Always include for license changes
    .build();
```

**For Child SKU Operations:**
```java
// Add child SKUs
.withChildSkus(Optional.of(List.of("ResolveHelpdesk-Child", "ResolveCamera-Child")))

// Remove all child SKUs
.withChildSkus(Optional.empty())

// Remove specific child, keep others (requires reading current state first)
.withChildSkus(Optional.of(List.of("ResolveCamera-Child"))) // Only keep Camera-Child
```

**For Complex Templates:**
```java
// Base template
var createBaseTemplate = new CreateSkuBuilder()
    .withProduct("gotoresolve")
    .withIsUnlimitedSku(true)
    .withIsUnifiedAdmin(true)
    .withProvides(List.of("resolve"))
    .withRoles(Set.of("ROLE_GOTORESOLVE_ORGANIZER"));

// Mobile variant
var createMobileTemplate = createBaseTemplate
    .withRoles(Set.of("ROLE_GOTORESOLVE_ORGANIZER", "ROLE_GOTORESOLVE_MOBILE_ORGANIZER"));
```

### Step 3: Set Up Pipeline

**Simple Pipeline (UpdateSkuStage):**
```java
var skuNamesChannel = new Channel<String>();
var skuUpdatesChannel = new Channel<String>();
var runSkuUpdateChannel = new Channel<String>();

Runnable runSkuUpdate = () -> {
    try {
        UploadSkus.main(args);
    } catch (InterruptedException | IOException e) {
        throw new RuntimeException(e);
    }
};

var pipeline = new Pipeline();
pipeline.add(new SeedStage<>(skuNamesChannel, skuNames));
pipeline.add(new UpdateSkuStage(skuNamesChannel, skuUpdatesChannel, fs, updateSku));
pipeline.add(new RunOnCloseStage<>(skuUpdatesChannel, runSkuUpdateChannel, runSkuUpdate));
pipeline.startMonitorAndJoin();
```

**Function-Based Pipeline (UpdateSkuStage):**
```java
// Function mapping for per-SKU updates
Function<String, UpdateSkuRequest> updateFunction = skuName ->
    switch (skuName) {
        case "ResolveStarter" -> new UpdateSkuBuilder()
            .withRoles(roles)
            .withChildSkus(Optional.empty()) // Remove child
            .withLicenseAttributes(true)
            .build();
        case "ResolveMSPLaunch", "ResolveMSPLaunchTrial" -> new UpdateSkuBuilder()
            .withRoles(roles)
            .withLicenseAttributes(true)
            .build();
        default -> throw new IllegalArgumentException("Unknown SKU: " + skuName);
    };

var pipeline = new Pipeline();
pipeline.add(new SeedStage<>(skuNamesChannel, skuNames));
pipeline.add(new UpdateSkuStage(skuNamesChannel, skuUpdatesChannel, fs, updateFunction, false));
pipeline.add(new RunOnCloseStage<>(skuUpdatesChannel, runSkuUpdateChannel, runSkuUpdate));
pipeline.startMonitorAndJoin();
```

**Complex Pipeline (CreateOrUpdateSkuStage):**
```java
// Function mapping for different SKUs
Function<String, CreateSkuRequest> createFunction = skuName ->
    switch (skuName) {
        case "NewSku1" -> createTemplate1.withSkuName(skuName).build();
        case "NewSku2" -> createTemplate2.withSkuName(skuName).build();
        default -> null; // No create needed
    };

Function<String, UpdateSkuRequest> updateFunction = skuName ->
    switch (skuName) {
        case "ExistingSku1" -> updateTemplate1.build();
        case "ExistingSku2" -> updateTemplate2.build();
        default -> throw new IllegalArgumentException("Unknown SKU: " + skuName);
    };

pipeline.add(new CreateOrUpdateSkuStage(inputChannel, outputChannel, fs,
    createFunction, updateFunction));
```

## CreateOrUpdateSkuStage Pattern

### When to Use
- Creating new SKUs that may not exist yet
- Updating SKU definitions and applying to existing licenses
- When you need both create and update logic

### Structure
```java
Function<String, CreateSkuRequest> createFn = skuName ->
    new CreateSkuBuilder()
        .withSkuName(skuName)
        .withProduct("g2c")
        .withDescription("Description")
        .withRoles(Set.of("ROLE_PRODUCT_ORGANIZER"))
        .withLicenseEntitlements(Map.of("product", Map.of("attr", value)))
        .build();

Function<String, UpdateSkuRequest> updateFn = skuName ->
    new UpdateSkuBuilder()
        .withDescription("Description")
        .withLicenseAttributes(true)
        .withRoles(Set.of("ROLE_PRODUCT_ORGANIZER"))
        .withLicenseEntitlements(Optional.of(Map.of("product", Map.of("attr", value))))
        .build();

pipeline.add(new CreateOrUpdateSkuStage(inputChannel, outputChannel, fs, createFn, updateFn));
```

### Key Differences from UpdateSkuStage
- Takes two functions: create and update
- Attempts create first; falls back to update if SKU exists
- Create function uses `CreateSkuBuilder`
- Update function uses `UpdateSkuBuilder` with `Optional` wrappers

## License Sweep Pattern

### When to Use
- After SKU updates when existing licenses need the changes
- When applying new entitlements to all licenses of a SKU
- When updating roles on existing licenses

### Complete Pipeline
```java
// 1. Update SKU definitions
CreateOrUpdateSkuStage (or UpdateSkuStage)
↓
// 2. Re-inject SKU names to start sweep
InjectOnCloseStage
↓
// 3. Partition for parallel processing
PartitionStage (10,000 per partition)
↓
// 4. Scan licenses by attribute
ScanLicensesByAttrStage
↓
// 5. Extract license keys
MapStage
↓
// 6. Update license entitlements or attributes
UpdateLicenseEntsStage (or UpdateLicenseAttrsStage)
↓
// 7. Upload SKUs to explorer
RunOnCloseStage (UploadSkus)
↓
DiscardingStage
```

### Example from IAM2152
```java
// Channels for license sweep
var skuNamesPartitionChannel = new Channel<String>(bufferSize);
var partitionsChannel = new Channel<RangeValue<String>>(bufferSize);
var licensesChannel = new Channel<License>(bufferSize);
var licenseKeysChannel = new Channel<Long>(bufferSize);
var updatedLicensesChannel = new Channel<Long>(bufferSize);

// Pipeline with sweep
pipeline.add(new UpdateSkuStage(skuNamesChannel, skuUpdatesChannel, fs, updateFunction, false));
pipeline.add(new InjectOnCloseStage(skuUpdatesChannel, skuNamesPartitionChannel, skuNames));
pipeline.add(new PartitionStage<>(skuNamesPartitionChannel, partitionsChannel, 10));
pipeline.add(new ScanLicensesByAttrStage<>(partitionsChannel, licensesChannel, 20, as, "sku", License.class));
pipeline.add(new MapStage<>(licensesChannel, licenseKeysChannel, License::getKey));
pipeline.add(new UpdateLicenseAttrsStage(licenseKeysChannel, updatedLicensesChannel, 5, as, licenseUpdate));
pipeline.add(new RunOnCloseStage<>(updatedLicensesChannel, runSkuUpdate));
```

### License Update Stages

**UpdateLicenseEntsStage**: Updates entitlements (product-specific features)
```java
var licenseEnts = Map.of("blockpstn", false, "maxattendees", 250);
pipeline.add(new UpdateLicenseEntsStage(inputChannel, outputChannel, 15, as, licenseEnts));
```

**UpdateLicenseAttrsStage**: Updates attributes (roles, descriptions, etc.)
```java
var licenseUpdate = new License();
licenseUpdate.setRoles(roles.stream().toList());
pipeline.add(new UpdateLicenseAttrsStage(inputChannel, outputChannel, 5, as, licenseUpdate));
```

### Scan Attributes
- `"ofsSku"` - OFS SKU name (most common for fulfillment service)
- `"sku"` - Legacy SKU attribute (used with account service)

### Partition Sizes
- Standard: 10,000 licenses per partition
- Smaller batches (10-100) for testing or small deployments
- Adjust based on expected license volume

## Common Roles and Entitlements

### Standard Roles
```java
// Base roles
"ROLE_GOTORESOLVE_ORGANIZER"                    // Basic organizer access
"ROLE_GOTORESOLVE_MOBILE_ORGANIZER"            // Mobile device access
"ROLE_GOTORESOLVE_CAMERA_SHARE_ORGANIZER"      // Camera sharing features

// Legacy roles (avoid in new implementations)
"ROLE_GOTORESOLVE_ADMIN"                       // Deprecated, use ORGANIZER

// Other product roles
"ROLE_GOTOMEETING_ORGANIZER"                   // GoToMeeting
"ROLE_GOTOWEBINAR_ORGANIZER"                   // GoToWebinar
```

### Common Child SKUs
```java
"ResolveHelpdesk-Child"        // Helpdesk functionality
"ResolveCamera-Child"          // Camera sharing features
"G2CPremiumL-Meeting"          // Meeting add-on for premium licenses
"CCCompleteL"                  // Complete license child
```

### Standard Entitlements
```java
// Trial prevention
.withPersistentAccountEntitlements(Map.of("gotoresolve", Map.of("canstarttrial", false)))

// Product access
.withProvides(List.of("resolve"))              // Resolve access
.withProvides(List.of("resolve", "meeting"))   // Multi-product access

// SKU properties
.withIsUnlimitedSku(true)                      // Unlimited usage
.withIsUnifiedAdmin(true)                      // Unified admin interface
.withIsAddonSku(true)                         // Add-on SKU (not standalone)
```

## Testing and Deployment

### Environment Progression
1. **ED** (Development): Initial testing
2. **RC** (Release Candidate): Pre-production validation
3. **Stage**: Final testing before production
4. **Prod**: Production deployment
5. **LIVE Sweep**: Update existing accounts

### Execution Commands
```bash
# Test in ED environment
java -cp [classpath] com.getgo.identity.tickets.IAM#### ED

# Deploy to RC
java -cp [classpath] com.getgo.identity.tickets.IAM#### RC

# And so on...
```

### Verification Steps
1. Check pipeline execution logs for errors
2. Verify UploadSkus completes successfully
3. Validate SKU changes in target environment
4. Test affected functionality before promoting

## Troubleshooting Common Issues

### Import Problems
- **Missing UpdateSkuBuilder**: Add `import com.getgo.ofs.domain.UpdateSkuBuilder;`
- **Missing Optional**: Add `import java.util.Optional;`
- **Stage not found**: Verify correct stage import path

### Runtime Errors
- **SKU not found**: Check SKU name spelling and existence in target environment
- **Role validation**: Ensure roles exist and are properly formatted
- **Pipeline hanging**: Check channel setup and ensure proper pipeline closure

### Best Practices
- **Always use withLicenseAttributes(true)** for license-related changes
- **Test in ED first** before promoting to other environments
- **Follow existing naming patterns** from similar tickets
- **Include comprehensive error handling** in pipeline stages
- **Document complex logic** with inline comments

This guide ensures consistent, maintainable ticket implementations following established patterns.