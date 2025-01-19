#!/bin/bash

# Function to check the status of GitHub Actions job for all repos of the organization
check_approval_status() {
    local ORG_NAME=$1
    local GITHUB_TOKEN=$2

    # Fetach all repositories for the organization
    local REPOS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/orgs/$ORG_NAME/repos" | jq -r '.[].name')

    for REPO in $REPOS; do
        # Fecth workflows for each repository
        local WORKFLOWS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.repos/$ORG_NAME/$REPO/actions/runs" | jq -r '.workflows_runs[] | select(.status=="in_progress") | .id')

        for RUN_ID in $WORKFLOWS; do
            # Check the status of manual approval job in each run
            local STATUS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                "https://api.github.com/repos/$ORG_NAME/$REPO/actions/runs/$RUN_ID/jobs" | jq -r '.jobs[] | select(.name=="Manual Approval") | status')

            if [ "$STATUS" == "completed" ]; then
                echo "Approval received for $ORG_NAME/$REPO workflow run $RUN_ID. Proceeding with the next steps."
            else
                echo "Waiting for approval on $ORG_NAME/$REPO workflow run $RUN_ID ..."
            fi
        done
    done
}

# Variables
$ORG_NAME="waycarbon"
$GITHUB_TOKEN=""

# Check for approval status in a loop
while true; do
    check_approval_status $ORG_NAME $GITHUB_TOKEN
    sleep 60 # Check every 60 seconds
done