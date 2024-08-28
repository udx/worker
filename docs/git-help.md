# Git Commands

## 1. Clean Ignored Files from Git

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

## 2. Override the Last Commit

If you want to modify the last commit (e.g., change the commit message or add new changes), you can amend it:

```shell
git commit --amend
```

- `--amend`: This option allows you to modify the most recent commit.
- You will be prompted to edit the commit message in your default text editor. You can either update the message or keep it as is.

> Note: Use --amend with caution, especially if the commit has already been pushed to a shared repository, as it rewrites history.

## 3. Force Push Amended Commit

After amending a commit, if the changes have already been pushed to a remote repository, you'll need to force push the updated commit:

```shell
git push -f
```

- `-f` or `--force`: This option forces Git to push the amended commit to the remote repository, rewriting history.

> Note: Force pushing can overwrite changes in the remote repository, so use it carefully, especially when working in a shared environment.

