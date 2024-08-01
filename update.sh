#!/bin/bash

# At the beginning of the script, add this global variable
IN_SUBMODULE=false

# Function to execute command, print to stdout, and log
execute_and_log() {
    local command="$*"
    echo "\$ $command"
    local log_file="/dev/null"
    if [ "$IN_SUBMODULE" = true ]; then
        log_file="/dev/null"
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

# Check if we're in the top-level directory of the repo
if [ ! -d ".git" ] || [ ! -f ".gitmodules" ]; then
    echo "Error: This script must be run from the top-level directory of the aipc-challenges repository."
    exit 1
fi

# Prompt for GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME

execute_and_log git fetch --all
execute_and_log git checkout "S24-$GITHUB_USERNAME"
execute_and_log git fetch upstream main:main
execute_and_log git rebase main

submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

for submodule in $submodules; do
    echo "Processing submodule: $submodule"
    (
        cd "$submodule"
        execute_and_log git fetch --all
        execute_and_log git checkout "S24-$submodule-$GITHUB_USERNAME"
        execute_and_log git fetch upstream "S24-$submodule:S24-$submodule"
        execute_and_log git rebase "S24-$submodule"
        
        execute_and_log git push -f origin "S24-$submodule-$GITHUB_USERNAME"
    )
done

execute_and_log git push -f origin "S24-$GITHUB_USERNAME"
execute_and_log git push origin main

echo "(Update completed successfully!)"
echo ""
