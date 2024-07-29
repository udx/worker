#!/bin/bash

set -e

# Create a new release on GitHub
response=$(curl -s -X POST \
-H "Authorization: token ${GITHUB_TOKEN}" \
-H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/${GITHUB_REPOSITORY}/releases \
-d @- << EOF
{
  "tag_name": "${semVer}",
  "target_commitish": "main",
  "name": "${semVer}",
  "body": "${changelog}",
  "draft": false,
  "prerelease": false
}
EOF
)

# Check for errors in the response
if echo "${response}" | grep -q "errors"; then
  echo "Failed to create release: ${response}"
  exit 1
else
  echo "Release created successfully."
fi
