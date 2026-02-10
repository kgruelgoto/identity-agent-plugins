# Java Ticket Generator Examples

## Example 1: Simple Role Update

**Input**: "IAMTASKS-2152: Add Mobile organizer role to ResolveMSPLaunch, ResolveMSPLaunchTrial, ResolveStarter"

**Generated Output**: IAM2152.java with:
- Three target SKUs
- Mobile + Organizer role combination
- Simple UpdateSkuStage pipeline
- Standard environment setup

## Example 2: Function-Based Updates

**Input**: "Remove child SKU from ResolveStarter but keep roles, update other SKUs with new roles"

**Generated Pattern**: Function-based UpdateSkuStage with per-SKU logic

## Example 3: Complex Template

**Input**: "Create new Resolve Premium SKUs with mobile, helpdesk child, and trial variants"

**Generated Pattern**: CreateOrUpdateSkuStage with multiple templates

## Example 4: SKU Creation with License Sweep (IAMTASKS-1999)

**Jira Ticket**: IAMTASKS-1999
**Generated File**: `IAM1999.java` (note: class name strips "TASKS" prefix)

**Ticket Description**:
```
Create new SKU for GoToConnect Internal Dial Only Handset

**License Name:** GoToConnect Internal Dial Only Handset
**OFS Template Name (BOSS):** G2CInternalOnlyL
**OFS Template Name (JIVE):** G2CInternalOnlyU

This should be a copy of the G2CLowUsage template with an additional
license attribute called blockpstn (boolean, default false).

This is an add-on license type.

Update all existing G2CLowUsage licenses to include the new blockpstn attribute.
```

**Generated Code**: IAM1999.java

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

public class IAM1999 {
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

        var product = "g2c";
        var skuNames = List.of("G2CInternalOnlyL", "G2CInternalOnlyU");

        // Note: In actual implementation, need to fetch G2CLowUsage entitlements
        // and merge with new blockpstn attribute
        Map<String, Map<String, Object>> licenseEntitlements = Map.of(
            "g2c", Map.of(
                "blockpstn", false
                // ... other entitlements from G2CLowUsage
            )
        );

        Function<String, CreateSkuRequest> createSkuFn = skuName ->
            new CreateSkuBuilder()
                .withSkuName(skuName)
                .withProduct(product)
                .withDescription("GoToConnect Internal Dial Only Handset")
                .withIsAddonSku(true)
                .withRoles(Set.of("ROLE_JIVE_USER"))
                .withLicenseEntitlements(licenseEntitlements)
                .build();

        Function<String, UpdateSkuRequest> updateSkuFn = skuName ->
            new UpdateSkuBuilder()
                .withDescription("GoToConnect Internal Dial Only Handset")
                .withLicenseAttributes(true)
                .withRoles(Set.of("ROLE_JIVE_USER"))
                .withLicenseEntitlements(Optional.of(licenseEntitlements))
                .build();

        var licenseEntsUpdate = Map.of("blockpstn", false);

        Runnable runSkuUpdate = () -> {
            try {
                UploadSkus.main(args);
            } catch (InterruptedException | IOException e) {
                throw new RuntimeException(e);
            }
        };

        var bufferSize = 1_024;
        var skuNamesChannel = new Channel<String>(bufferSize);
        var skuUpdatesChannel = new Channel<String>(bufferSize);
        var skuNamesPartitionChannel = new Channel<String>(bufferSize);
        var partitionsChannel = new Channel<RangeValue<String>>(bufferSize);
        var licensesChannel = new Channel<License>(bufferSize);
        var licenseKeysChannel = new Channel<Long>(bufferSize);
        var updatedLicensesChannel = new Channel<Long>(bufferSize);
        var runSkuUpdateChannel = new Channel<Long>(bufferSize);

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

**Pattern Used**: SKU Creation with License Sweep
- CreateOrUpdateSkuStage for new SKUs
- License sweep to update existing licenses
- Partition by 10,000 for parallel processing
- UpdateLicenseEntsStage for entitlement changes

**Execution**:
```bash
# Compile
mvn clean compile

# Test in dev
java -cp target/as-ofs-tools-*-jar-with-dependencies.jar \
  com.getgo.identity.tickets.IAM1999 dev

# Deploy through environments
java ... com.getgo.identity.tickets.IAM1999 ED
java ... com.getgo.identity.tickets.IAM1999 RC
java ... com.getgo.identity.tickets.IAM1999 Stage
java ... com.getgo.identity.tickets.IAM1999 Prod
```

## Standard Code Blocks

### Required Imports
```java
import com.getgo.identity.channel.Channel;
import com.getgo.identity.channel.Pipeline;
import com.getgo.identity.channel.RunOnCloseStage;
import com.getgo.identity.channel.SeedStage;
import com.getgo.identity.environment.Environment;
import com.getgo.identity.environment.Kms;
import com.getgo.identity.stage.UpdateSkuStage;
import com.getgo.identity.tools.UploadSkus;
import com.getgo.ofs.domain.UpdateSkuBuilder;
```

### Environment Setup Pattern
```java
if (args.length != 1) {
    System.out.println("1 argument required: [environment]");
    return;
}

var env = Environment.environment(args[0], new Kms());
var auth = env.authorizationService();
var tokenTask = env.clientTokenManagerTask(auth);
var fs = env.fulfillmentService(tokenTask);
```

### Pipeline Execution Pattern
```java
Runnable runSkuUpdate = () -> {
    try {
        UploadSkus.main(args);
    } catch (InterruptedException | IOException e) {
        throw new RuntimeException(e);
    }
};

pipeline.add(new RunOnCloseStage(runSkuUpdateChannel, runSkuUpdate));
pipeline.startMonitorAndJoin();
```