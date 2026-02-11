#!/usr/bin/env node
/**
 * Find all paths where a property exists in SKU data
 *
 * Usage: node find-property-paths.js <skus-file> <property-name>
 *
 * This script searches through all SKUs and finds every location where
 * the specified property appears, showing the full JSON path.
 *
 * Arguments:
 *   skus-file: Path to the SKU data file (JavaScript format)
 *   property-name: Property name to search for (case-insensitive)
 *
 * Example:
 *   node find-property-paths.js /tmp/skus.js transcriptsprovisioned
 */

const fs = require('fs');

// Parse arguments
const [,, skusFile, propertyName] = process.argv;

if (!skusFile || !propertyName) {
  console.error('Usage: node find-property-paths.js <skus-file> <property-name>');
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
 * Recursively find all paths where a property exists
 */
function findAllPropertyPaths(obj, targetLower, currentPath = '', results = []) {
  if (typeof obj !== 'object' || obj === null) {
    return results;
  }

  for (const key in obj) {
    const fullPath = currentPath ? `${currentPath}.${key}` : key;

    // Check if this key matches (case-insensitive)
    if (key.toLowerCase() === targetLower) {
      results.push({
        path: fullPath,
        actualName: key,
        value: obj[key],
        valueType: typeof obj[key]
      });
    }

    // Recursively search nested objects (but not arrays)
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      findAllPropertyPaths(obj[key], targetLower, fullPath, results);
    }
  }

  return results;
}

// Collect all unique paths across all SKUs
const pathMap = new Map(); // path -> { count, exampleValue, actualNames }

skus.forEach((sku) => {
  const paths = findAllPropertyPaths(sku, targetProp);
  paths.forEach(({ path, actualName, value, valueType }) => {
    if (!pathMap.has(path)) {
      pathMap.set(path, {
        path,
        actualNames: new Set(),
        count: 0,
        exampleValue: value,
        valueType
      });
    }
    const entry = pathMap.get(path);
    entry.actualNames.add(actualName);
    entry.count++;
  });
});

// Convert to output format
const results = Array.from(pathMap.values()).map(entry => ({
  path: entry.path,
  actualNames: Array.from(entry.actualNames),
  occurrences: entry.count,
  exampleValue: entry.exampleValue,
  valueType: entry.valueType
}));

// Sort by occurrence count (descending)
results.sort((a, b) => b.occurrences - a.occurrences);

// Output results
if (results.length === 0) {
  console.log(JSON.stringify({
    property: propertyName,
    found: false,
    message: `Property "${propertyName}" not found in any SKU`
  }, null, 2));
} else {
  console.log(JSON.stringify({
    property: propertyName,
    found: true,
    uniquePaths: results.length,
    totalOccurrences: results.reduce((sum, r) => sum + r.occurrences, 0),
    paths: results
  }, null, 2));
}
