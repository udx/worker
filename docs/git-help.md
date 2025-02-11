## Git Commands

### 1. Clean Ignored Files from Git

Sometimes you may need to remove all files that are listed in your .gitignore from the repository's index but keep them in your working directory. This command helps you do that:

```shell
git rm -r --cached .
```

- `rm -r --cached .`: This removes all files from the Git index, including ignored files.
- `.`: Refers to the current directory, so it applies the command recursively to all files and directories.

After running this command, you need to commit the changes to update the repository:

```shell
git add .
git commit -m "Cleaned up ignored files"
```

### 2. Override the Last Commit

If you want to modify the last commit (e.g., change the commit message or add new changes), you can amend it:

```shell
git commit --amend
```

- `--amend`: This option allows you to modify the most recent commit.
- You will be prompted to edit the commit message in your default text editor. You can either update the message or keep it as is.

> Note: Use --amend with caution, especially if the commit has already been pushed to a shared repository, as it rewrites history.

### 3. Force Push Amended Commit

After amending a commit, if the changes have already been pushed to a remote repository, you'll need to force push the updated commit:

```shell
git push -f
```

- `-f` or `--force`: This option forces Git to push the amended commit to the remote repository, rewriting history.

> Note: Force pushing can overwrite changes in the remote repository, so use it carefully, especially when working in a shared environment.

### 4. Moving Unpushed Commits Between Branches

If you need to move an unpushed commit from one branch to another, you can use git cherry-pick. Here's an example of moving a commit from branch `UAT-69` to branch `1629`:

1. First, identify the unpushed commit on the source branch:
```shell
git log UAT-69 --not --remotes --oneline
```

2. Note the commit hash from the output (e.g., `4cff367`)

3. Switch to the target branch and stash any current changes:
```shell
git checkout 1629
git stash  # if you have uncommitted changes
```

4. Cherry-pick the commit:
```shell
git cherry-pick 4cff367
```

5. Restore your stashed changes if any:
```shell
git stash pop
```

> Note: The cherry-pick command creates a new commit on the target branch with the same changes but a different commit hash.
