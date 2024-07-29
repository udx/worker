#!/bin/bash

set -e

# Environment Variables
GITHUB_TOKEN=$GITHUB_TOKEN
GITHUB_REPOSITORY=$GITHUB_REPOSITORY
SEMVER=$semVer
CHANGELOG=$changelog

# Create GitHub Release
RELEASE_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$GITHUB_REPOSITORY/releases \
  -d @- <<EOF
{
  "tag_name": "v$SEMVER",
  "name": "Release v$SEMVER",
  "body": "$CHANGELOG"
}
EOF
)

# Extract the release ID from the response
RELEASE_ID=$(echo "$RELEASE_RESPONSE" | jq -r '.id')

# Function to upload release asset
upload_asset() {
  local RELEASE_ID=$1
  local ASSET_PATH=$2
  local ASSET_NAME=$3

  curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: $(file -b --mime-type "$ASSET_PATH")" \
    --data-binary @"$ASSET_PATH" \
    "https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets?name=$ASSET_NAME"
}

# Example of uploading an asset (if any)
# upload_asset "$RELEASE_ID" "path/to/your/asset.zip" "asset.zip"
