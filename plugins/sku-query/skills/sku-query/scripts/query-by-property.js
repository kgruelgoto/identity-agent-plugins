#!/usr/bin/env node
/**
 * Case-insensitive SKU property search
 *
 * Usage: node query-by-property.js <skus-file> <property-name> [output-format]
 *
 * Arguments:
 *   skus-file: Path to the SKU data file (JavaScript format)
 *   property-name: Property name to search for (case-insensitive)
 *   output-format: 'full' (default) | 'names-only' | 'count'
 *
 * Examples:
 *   node query-by-property.js /tmp/skus.js dialPlanSmsNodeProvisioned
 *   node query-by-property.js /tmp/skus.js aiReceptionistSendSmsAllowed full
 *   node query-by-property.js /tmp/skus.js transcriptsprovisioned names-only
 */

const fs = require('fs');
const path = require('path');

// Parse arguments
const [,, skusFile, propertyName, outputFormat = 'full'] = process.argv;

if (!skusFile || !propertyName) {
  console.error('Usage: node query-by-property.js <skus-file> <property-name> [output-format]');
  console.error('Output formats: full (default), names-only, count');
  process.exit(1);
}

// Check if file exists
if (!fs.existsSync(skusFile)) {
  console.error(`Error: File not found: ${skusFile}`);
  process.exit(1);
}

// Load and eval the SKU data
try {
  eval(fs.readFileSync(skusFile, 'utf8'));
} catch (error) {
  console.error(`Error loading SKU data: ${error.message}`);
  process.exit(1);
}

// Check if skus variable was created
if (typeof skus === 'undefined') {
  console.error('Error: SKU data file did not define "skus" variable');
  process.exit(1);
}

const targetProp = propertyName.toLowerCase();

/**
 * Recursively find a property by name (case-insensitive)
 * Returns: { found: boolean, path: string, value: any } or null
 */
function findPropertyInObject(obj, targetLower, currentPath = '') {
  if (typeof obj !== 'object' || obj === null) {
    return null;
  }

  for (const key in obj) {
    const fullPath = currentPath ? `${currentPath}.${key}` : key;

    // Check if this key matches (case-insensitive)
    if (key.toLowerCase() === targetLower) {
      return {
        found: true,
        path: fullPath,
        value: obj[key]
      };
    }

    // Recursively search nested objects (but not arrays)
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      const result = findPropertyInObject(obj[key], targetLower, fullPath);
      if (result) {
        return result;
      }
    }
  }

  return null;
}

// Find all SKUs with the property
const results = [];
skus.forEach((sku) => {
  const match = findPropertyInObject(sku, targetProp);
  if (match) {
    results.push({
      skuName: sku.skuName,
      product: sku.product,
      description: sku.licenseAttributes?.description || '',
      propertyPath: match.path,
      propertyValue: match.value
    });
  }
});

// Output based on format
switch (outputFormat) {
  case 'count':
    console.log(results.length);
    break;

  case 'names-only':
    if (results.length === 0) {
      console.log('No SKUs found with property:', propertyName);
    } else {
      results.forEach(r => console.log(r.skuName));
    }
    break;

  case 'full':
  default:
    if (results.length === 0) {
      console.log(JSON.stringify({
        property: propertyName,
        found: false,
        count: 0,
        skus: []
      }, null, 2));
    } else {
      console.log(JSON.stringify({
        property: propertyName,
        found: true,
        count: results.length,
        skus: results
      }, null, 2));
    }
    break;
}
