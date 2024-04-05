# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install git before running this script."
    exit 1
fi

# Init and push to remote repository
gh_repo_add() {
    repo_org=$1
    repo_name=$2
    branch=${3:-main}
    commit_message=${4:-"first commit"}
    
    if [[ -z $repo_org || -z $repo_name ]]; then
        nice_logs "Repo org or name is empty" "error"
        exit 1
    fi
    
    # TODO: AI generated description
    echo "# ${repo_name}" >> README.md
    
    git init
    git add README.md
    git commit -m "$commit_message"
    git branch -M $branch
    git remote add origin git@github.com:${repo_org}/${repo_name}.git
    git push -u origin $branch
    
    if ! git push -u origin $branch; then
        nice_logs "Failed to push to remote repository" "error"
        exit 1
    fi
}

# Push repo to remote
gh_repo_push() {
    repo_org=$1
    repo_name=$2
    branch=${3:-main}
    
    if [[ -z $repo_org || -z $repo_name ]]; then
        nice_logs "Repo org or name is empty" "error"
        exit 1
    fi
    
    git remote add origin git@github.com:${repo_org}/${repo_name}.git
    git branch -M $branch
    git push -u origin $branch
    
    if ! git push -u origin $branch; then
        nice_logs "Failed to push to remote repository" "error"
        exit 1
    fi
}