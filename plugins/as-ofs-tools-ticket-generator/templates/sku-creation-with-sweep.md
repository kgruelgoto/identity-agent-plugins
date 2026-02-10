# SKU Creation with License Sweep Template

This template handles the most common ticket pattern (60% of use cases): Creating or updating SKU definitions and sweeping existing licenses to apply the changes.

## Pattern Overview

Based on tickets like IAM1525, IAM1814, IAM1870, IAM2152, this pattern:
1. Creates new SKUs or updates existing SKUs with CreateOrUpdateSkuStage
2. Sweeps existing licenses to apply entitlement/attribute changes
3. Uses partition-based parallel processing for scalability
4. Uploads SKU definitions to explorer

## When to Use This Pattern

- Creating new SKUs with specific entitlements
- Updating existing SKU definitions and applying to all licenses
- Adding/removing license or account entitlements
- Copying from existing templates with modifications

## Pipeline Stages

```
SeedStage (SKU names)
  ↓
CreateOrUpdateSkuStage (define SKUs)
  ↓
InjectOnCloseStage (re-inject SKU names for sweep)
  ↓
PartitionStage (partition by 10,000 for parallel processing)
  ↓
ScanLicensesByAttrStage (scan licenses by SKU attribute)
  ↓
MapStage (extract license keys)
  ↓
UpdateLicenseEntsStage or UpdateLicenseAttrsStage (apply changes)
  ↓
RunOnCloseStage (run UploadSkus.main())
  ↓
DiscardingStage
```

## Complete Template

```java
package com.getgo.identity.tickets;

import com.citrix.account.domain.License;
import com.getgo.identity.channel.Channel;
import com.getgo.identity.channel.DiscardingStage;
import com.getgo.identity.channel.InjectOnCloseStage;
import com.getgo.identity.channel.MapStage;
import com.getgo.identity.channel.PartitionStage;
import com.getgo.identity.channel.Pipeline;
import com.getgo.identity.channel.RangeValue;
import com.getgo.identity.channel.RunOnCloseStage;
import com.getgo.identity.channel.SeedStage;
import com.getgo.identity.environment.Environment;
import com.getgo.identity.environment.Kms;
import com.getgo.identity.stage.CreateOrUpdateSkuStage;
import com.getgo.identity.stage.ScanLicensesByAttrStage;
import com.getgo.identity.stage.UpdateLicenseEntsStage;
import com.getgo.identity.tools.UploadSkus;
import com.getgo.ofs.domain.CreateSkuBuilder;
import com.getgo.ofs.domain.CreateSkuRequest;
import com.getgo.ofs.domain.UpdateSkuBuilder;
import com.getgo.ofs.domain.UpdateSkuRequest;

import java.io.IOException;
import java.util.*;
import java.util.function.Function;

public class IAM#### {
    public static void main(String[] args) throws InterruptedException {
        if (args.length != 1) {
            System.out.println("1 argument required: [environment]");
            return;
        }

        var env = Environment.environment(args[0], new Kms());
        var auth = env.authorizationService();
        var tokenTask = env.clientTokenManagerTask(auth);
        var fs = env.fulfillmentService(tokenTask);
        var as = env.accountService();

        // Configuration from Jira ticket
        var product = "g2c";  // Extract from ticket
        var skuNames = List.of("Sku1", "Sku2");  // Extract from ticket

        // License entitlements (what changes on licenses)
        Map<String, Map<String, Object>> licenseEntitlements = Map.of(
            product, Map.of(
                "newattr", true,
                "existingattr", "value"
            )
        );

        // Account entitlements (what changes on accounts)
        Map<String, Map<String, Object>> accountEntitlements = Map.of(
            product, Map.of(
                "accountattr", false
            )
        );

        // Create function for new SKUs
        Function<String, CreateSkuRequest> createSkuFn = skuName ->
            new CreateSkuBuilder()
                .withSkuName(skuName)
                .withProduct(product)
                .withDescription("Description from ticket")
                .withIsAddonSku(true)  // or false for standalone
                .withRoles(Set.of("ROLE_PRODUCT_ORGANIZER"))
                .withLicenseEntitlements(licenseEntitlements)
                .withAccountEntitlements(accountEntitlements)
                .build();

        // Update function for existing SKUs
        Function<String, UpdateSkuRequest> updateSkuFn = skuName ->
            new UpdateSkuBuilder()
                .withDescription("Description from ticket")
                .withLicenseAttributes(true)
                .withRoles(Set.of("ROLE_PRODUCT_ORGANIZER"))
                .withLicenseEntitlements(Optional.of(licenseEntitlements))
                .withAccountEntitlements(Optional.of(accountEntitlements))
                .build();

        // Entitlements to apply to existing licenses
        var licenseEntsUpdate = Map.of("newattr", true);

        Runnable runSkuUpdate = () -> {
            try {
                UploadSkus.main(args);
            } catch (InterruptedException | IOException e) {
                throw new RuntimeException(e);
            }
        };

        // Channels
        var bufferSize = 1_024;
        var skuNamesChannel = new Channel<String>(bufferSize);
        var skuUpdatesChannel = new Channel<String>(bufferSize);
        var skuNamesPartitionChannel = new Channel<String>(bufferSize);
        var partitionsChannel = new Channel<RangeValue<String>>(bufferSize);
        var licensesChannel = new Channel<License>(bufferSize);
        var licenseKeysChannel = new Channel<Long>(bufferSize);
        var updatedLicensesChannel = new Channel<Long>(bufferSize);
        var runSkuUpdateChannel = new Channel<Long>(bufferSize);

        // Pipeline
        var pipeline = new Pipeline();
        pipeline.add(new SeedStage<>(skuNamesChannel, skuNames));
        pipeline.add(new CreateOrUpdateSkuStage(skuNamesChannel, skuUpdatesChannel, fs, createSkuFn, updateSkuFn));
        pipeline.add(new InjectOnCloseStage<>(skuUpdatesChannel, skuNamesPartitionChannel, skuNames));
        pipeline.add(new PartitionStage<>(skuNamesPartitionChannel, partitionsChannel, 10_000));
        pipeline.add(new ScanLicensesByAttrStage<>(partitionsChannel, licensesChannel, 15, as, "ofsSku", License.class));
        pipeline.add(new MapStage<>(licensesChannel, licenseKeysChannel, License::getKey));
        pipeline.add(new UpdateLicenseEntsStage(licenseKeysChannel, updatedLicensesChannel, 15, as, licenseEntsUpdate));
        pipeline.add(new RunOnCloseStage<>(updatedLicensesChannel, runSkuUpdateChannel, runSkuUpdate));
        pipeline.add(new DiscardingStage<>(runSkuUpdateChannel));
        pipeline.startMonitorAndJoin();
    }
}
```

## Key Components

### CreateOrUpdateSkuStage
- Takes two functions: createFn and updateFn
- Tries to create SKU first; if exists, updates instead
- Use for new SKUs or updating existing definitions

### ScanLicensesByAttrStage
- Scans licenses by attribute (usually "ofsSku" or "sku")
- Partitioned for parallel processing (10,000 per partition)
- Returns License objects

### UpdateLicenseEntsStage
- Updates license entitlements (product-specific features)
- Use when changing license-level capabilities

### UpdateLicenseAttrsStage (alternative)
- Updates license attributes (roles, descriptions, etc.)
- Use when changing roles or basic license properties

## Variations

### Simple SKU Update (no license sweep)
If only updating SKU definitions without touching existing licenses:
```java
pipeline.add(new CreateOrUpdateSkuStage(...));
pipeline.add(new RunOnCloseStage<>(..., runSkuUpdate));
pipeline.add(new DiscardingStage<>(...));
```

### Per-SKU Configuration
For different SKUs needing different configs:
```java
Function<String, CreateSkuRequest> createSkuFn = skuName ->
    switch (skuName) {
        case "Sku1" -> createBuilder1.withSkuName(skuName).build();
        case "Sku2" -> createBuilder2.withSkuName(skuName).build();
        default -> throw new IllegalArgumentException("Unknown SKU: " + skuName);
    };
```

## Common Products and Attributes

**Products:**
- `g2c` - GoToConnect
- `gotoresolve` - GoTo Resolve
- `jive` - Jive (legacy voice)
- `g2m` - GoToMeeting

**Common Scan Attributes:**
- `ofsSku` - OFS SKU name (most common)
- `sku` - Legacy SKU attribute

**Partition Size:**
- Standard: 10,000 licenses per partition
- Adjust based on expected license volume

**Concurrency:**
- ScanLicensesByAttrStage: 15 concurrent workers
- UpdateLicenseEntsStage: 15 concurrent workers
- Adjust based on API rate limits
