#!/bin/bash
# Fetch SKU data from fulfillment service and prepare for querying
#
# Usage: fetch-skus.sh [output-file]
#   output-file: Optional path for output (default: /tmp/skus-data.js)
#
# Exits with:
#   0 - Success, SKU data written to output file
#   1 - Error fetching or processing data

set -euo pipefail

OUTPUT_FILE="${1:-/tmp/skus-data.js}"
MANIFEST_URL="https://iamdocs.serversdev.getgo.com/fs/live/skus-manifest.json"
BASE_URL="https://iamdocs.serversdev.getgo.com/fs/live"

# Fetch manifest and get current SKU file name
echo "Fetching SKU manifest..." >&2
MANIFEST=$(curl -sf "$MANIFEST_URL")
if [ $? -ne 0 ]; then
  echo "Error: Failed to fetch manifest from $MANIFEST_URL" >&2
  exit 1
fi

SKU_FILE=$(echo "$MANIFEST" | jq -r '.skusJs')
if [ -z "$SKU_FILE" ] || [ "$SKU_FILE" = "null" ]; then
  echo "Error: Could not extract skusJs from manifest" >&2
  exit 1
fi

# Download SKU data
SKU_URL="$BASE_URL/$SKU_FILE"
echo "Fetching SKU data from $SKU_URL..." >&2
curl -sf "$SKU_URL" -o "$OUTPUT_FILE"
if [ $? -ne 0 ]; then
  echo "Error: Failed to fetch SKU data from $SKU_URL" >&2
  echo "Attempting fallback to skus.js..." >&2

  # Try fallback
  curl -sf "$BASE_URL/skus.js" -o "$OUTPUT_FILE"
  if [ $? -ne 0 ]; then
    echo "Error: Fallback also failed" >&2
    exit 1
  fi
fi

# Verify the file was created and has content
if [ ! -s "$OUTPUT_FILE" ]; then
  echo "Error: Output file is empty or was not created" >&2
  exit 1
fi

# Verify it has the expected format
if ! head -n 1 "$OUTPUT_FILE" | grep -q "^skus = "; then
  echo "Error: Downloaded file does not have expected 'skus = ' format" >&2
  exit 1
fi

echo "Success: SKU data saved to $OUTPUT_FILE" >&2

# Count SKUs (strip semicolon if present)
SKU_COUNT=$(cat "$OUTPUT_FILE" | sed 's/^skus = //' | sed 's/;$//' | jq 'length' 2>/dev/null || echo "unknown")
echo "SKU count: $SKU_COUNT" >&2
exit 0
