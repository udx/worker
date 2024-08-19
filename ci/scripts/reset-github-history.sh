#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <new-branch-name> <main-branch-name>"
    exit 1
fi

# Set variables from input parameters
NEW_BRANCH="$1"
MAIN_BRANCH="$2"

# Step 1: Backup your current branch
echo "Creating a backup of the current branch..."
git checkout -b "backup-$(date +%Y%m%d%H%M%S)"

# Step 2: Create a new orphan branch
echo "Creating a new orphan branch..."
git checkout --orphan "$NEW_BRANCH"

# Step 3: Add all files to the new branch
echo "Adding all files to the new branch..."
git add -A

# Step 4: Commit the changes
echo "Committing changes..."
git commit -m "Initial commit with cleaned history"

# Step 5: Delete the old branch
echo "Deleting the old main branch..."
git branch -D "$MAIN_BRANCH"

# Step 6: Rename the new branch to main
echo "Renaming the new branch to $MAIN_BRANCH..."
git branch -m "$MAIN_BRANCH"

# Step 7: Force push to update the remote repository
echo "Force pushing the new history to remote repository..."
git push --force origin "$MAIN_BRANCH"

echo "Repository history has been cleared and restarted."
