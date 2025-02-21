# Git Quick Reference

## 🧹 Cleanup Operations

### Clean Ignored Files
Remove files from Git index while keeping them in working directory:

```bash
# Remove from index
git rm -r --cached .

# Commit the cleanup
git add .
git commit -m "chore: clean ignored files"
```

> 💡 Useful when `.gitignore` is updated but files are still tracked

## 🔄 Commit Management

### Amend Last Commit

```bash
# Change commit message only
git commit --amend -m "new message"

# Add staged changes to last commit
git add .
git commit --amend --no-edit
```

⚠️ **Warning**: Don't amend pushed commits unless working alone

### Force Push Changes

```bash
# Force push with lease (safer than -f)
git push --force-with-lease

# Force push (use with extreme caution)
git push -f
```

> 🛡️ Always prefer `--force-with-lease` over `-f` to prevent overwriting others' work

## 🌿 Branch Operations

### Move Commits Between Branches

```bash
# 1. Find unpushed commits
git log branch-name --not --remotes --oneline

# 2. Save current work
git stash

# 3. Switch and apply
git checkout target-branch
git cherry-pick <commit-hash>

# 4. Restore work
git stash pop
```

## 🚀 Common Workflows

### Feature Branch Workflow

```bash
# 1. Create feature branch
git checkout -b feature/name

# 2. Make changes and commit
git add .
git commit -m "feat: add new feature"

# 3. Update with main
git fetch origin
git rebase origin/main

# 4. Push changes
git push -u origin feature/name
```

### Commit Message Format

```bash
# Format
<type>(<scope>): <subject>

# Types
feat:     New feature
fix:      Bug fix
docs:     Documentation
style:    Formatting
refactor: Code restructure
test:     Tests
chore:    Maintenance
```

## 🔍 Inspection Commands

### View Changes

```bash
# Show staged changes
git diff --staged

# Show changes in last commit
git show HEAD

# Show file history
git log -p filename
```

### Branch Information

```bash
# List all branches
git branch -vv

# Show merged branches
git branch --merged

# Show unmerged branches
git branch --no-merged
```

## ⚡ Tips and Tricks

1. **Stash Management**:
   ```bash
   # Named stash
   git stash save "feature work in progress"
   
   # List stashes
   git stash list
   
   # Apply specific stash
   git stash apply stash@{n}
   ```

2. **Quick Fixes**:
   ```bash
   # Undo last commit but keep changes
   git reset --soft HEAD^
   
   # Discard all local changes
   git reset --hard HEAD
   ```

3. **Search History**:
   ```bash
   # Search commit messages
   git log --grep="keyword"
   
   # Search code changes
   git log -S"code string"
   ```
