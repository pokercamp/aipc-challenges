#!/bin/bash

# At the beginning of the script, add this global variable
IN_SUBMODULE=false

# Function to execute command, print to stdout, and log
execute_and_log() {
    local command="$*"
    echo "\$ $command"
    local log_file=".git/setup_log.txt"
    if [ "$IN_SUBMODULE" = true ]; then
        log_file="../.git/setup_log.txt"
    fi
    
    echo "$(date) $(pwd)\$ $command" >> "$log_file"
    
    # Execute command and capture output and error
    output=$("$@" 2>&1)
    exit_code=$?
    
    # Print and log the output
    echo "$output"
    echo "$output" >> "$log_file"
    echo "$(date): Exit code: $exit_code" >> "$log_file"
    echo "" >> "$log_file"
    
    # Check if the command failed
    if [ $exit_code -ne 0 ]; then
        echo "Error: Command failed with exit code $exit_code"
        exit 1
    fi
}

# New function for handling remote setup
setup_remote() {
    local remote_name="$1"
    local remote_url="$2"
    
    if git remote get-url "$remote_name" > /dev/null 2>&1; then
        current_url=$(git remote get-url "$remote_name")
        if [ "$current_url" != "$remote_url" ]; then
            execute_and_log git remote set-url "$remote_name" "$remote_url"
        else
            echo "(Remote $remote_name for $(basename $(pwd)) already set to $remote_url.)"
        fi
    else
        execute_and_log git remote add "$remote_name" "$remote_url"
    fi
}

# Check if we're in the top-level directory of the repo
if [ ! -d ".git" ] || [ ! -f ".gitmodules" ]; then
    echo "Error: This script must be run from the top-level directory of the aipc-challenges repository."
    exit 1
fi

# Prompt for GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME
echo "$(date): Script started for user: $GITHUB_USERNAME" >> .git/setup_log.txt

echo ""
echo "(Configure top level...)"

# Set origin to the user's fork
setup_remote "origin" "git@github.com:$GITHUB_USERNAME/aipc-challenges.git"

# Set upstream to the pokercamp repo
setup_remote "upstream" "git@github.com:pokercamp/aipc-challenges.git"

# Create and push new branch in main repo
BRANCH_NAME="S24-$GITHUB_USERNAME"
if git rev-parse --verify $BRANCH_NAME >/dev/null 2>&1; then
    echo "(Branch $BRANCH_NAME already exists. Checking out.)"
    execute_and_log git checkout "$BRANCH_NAME"
else
    execute_and_log git checkout -b "$BRANCH_NAME"
    execute_and_log git push -u origin "$BRANCH_NAME"
fi

echo ""
echo "(Configure submodules...)"

# Initialize and update submodules
execute_and_log git submodule update --init --recursive

# Set up each challenge submodule
for CHALLENGE_NAME in challenge-1 challenge-2-100cardkuhn challenge-2-leduc; do
    cd $CHALLENGE_NAME || { exit 1; }
    IN_SUBMODULE=true
    
    echo "$(date): Processing submodule: $CHALLENGE_NAME" >> ../.git/setup_log.txt

    setup_remote "origin" "git@github.com:$GITHUB_USERNAME/pokercamp-engine.git"
    setup_remote "upstream" "git@github.com:pokercamp/engine.git"

    UPSTREAM_BRANCH="S24-$CHALLENGE_NAME"
    PERSONAL_BRANCH="S24-$CHALLENGE_NAME-$GITHUB_USERNAME"
    
    # Check if this is a fresh setup for this submodule
    if [ ! -f "../.git/modules/$CHALLENGE_NAME/.setup_complete" ]; then
        echo "(Fresh setup for $CHALLENGE_NAME.)"
        execute_and_log git fetch upstream
        
        # Check if the personal branch already exists
        if git rev-parse --verify $PERSONAL_BRANCH >/dev/null 2>&1; then
            echo "(Branch $PERSONAL_BRANCH already exists. Checking out.)"
            execute_and_log git checkout $PERSONAL_BRANCH
        else
            execute_and_log git checkout -b $PERSONAL_BRANCH upstream/$UPSTREAM_BRANCH
        fi
        
        execute_and_log git push -u origin $PERSONAL_BRANCH
        touch "../.git/modules/$CHALLENGE_NAME/.setup_complete"
        echo "$(date): Completed fresh setup for $CHALLENGE_NAME" >> ../.git/setup_log.txt
    else
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        if [ "$CURRENT_BRANCH" != "$PERSONAL_BRANCH" ]; then
            read -p "Current branch ($CURRENT_BRANCH) is not $PERSONAL_BRANCH. Switch? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                execute_and_log git checkout $PERSONAL_BRANCH
            else
                echo "$(date): Kept current branch $CURRENT_BRANCH for $CHALLENGE_NAME" >> ../.git/setup_log.txt
            fi
        else
            echo "$(date): Already on correct branch $PERSONAL_BRANCH for $CHALLENGE_NAME" >> ../.git/setup_log.txt
        fi
    fi

    cd .. || { exit 1; }
    IN_SUBMODULE=false
    
    echo ""
done

echo "(Setup completed successfully!)"
echo ""
echo "$(date): Setup completed successfully" >> .git/setup_log.txt
