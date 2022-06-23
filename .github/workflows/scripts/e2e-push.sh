#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# We push to main a file e2e/wokflow-name.txt
# with the date inside, to be sure the file is different.

THIS_FILE=$(e2e_this_file)

DATE=$(date --utc)
FILE=e2e/$THIS_FILE.txt
COMMIT_MESSAGE="$GITHUB_WORKFLOW"
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)

# Check presence of file in the correct branch.
gh repo clone "$GITHUB_REPOSITORY" -- -b "$BRANCH"
REPOSITORY_NAME=$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f2)
cd ./"$REPOSITORY_NAME"

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
PUSH_TOKEN=$PAT_TOKEN
if [[ -z "$PUSH_TOKEN" ]]; then
    PUSH_TOKEN=$GH_TOKEN
fi

if [ -f "$FILE" ]; then
    echo "DEBUG: file $FILE exists on branch $BRANCH"

    SHA=$(curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $GH_TOKEN" -X GET "https://api.github.com/repos/$GITHUB_REPOSITORY/contents/$FILE?ref=$BRANCH" | jq -r '.sha')
    if [[ -z "$SHA" ]]; then
        echo "SHA is empty"
        exit 4
    fi

    echo -n "$DATE" >"$FILE"

    # Add the file content's sha to the request.
    cat <<EOF >DATA
{"branch":"$BRANCH","message":"$COMMIT_MESSAGE","sha":"$SHA","committer":{"name":"github-actions","email":"github-actions@github.com"},"content":"$(echo -n "$DATE" | base64 --wrap=0)"}
EOF

    # We must use a PAT here in order to trigger subsequent workflows.
    # See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
    # API ref: https://docs.github.com/en/rest/repos/contents#create-a-file.
    curl -s \
        -X PUT \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token $PUSH_TOKEN" \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/contents/$FILE" \
        -d @DATA
else
    echo "$DATE" >"$FILE"

    echo "DEBUG: file $FILE does not exist on branch $BRANCH"

    # We must use a PAT here in order to trigger subsequent workflows.
    # See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
    # API ref: https://docs.github.com/en/rest/repos/contents#create-a-file.
    curl -s \
        -X PUT \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token $PUSH_TOKEN" \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/contents/$FILE" \
        -d "{\"branch\":\"$BRANCH\",\"message\":\"$COMMIT_MESSAGE\",\"committer\":{\"name\":\"github-actions\",\"email\":\"github-actions@github.com\"},\"content\":\"$(echo -n "$DATE" | base64 --wrap=0)\"}"
fi

# git config --global user.name github-actions
# git config --global user.email github-actions@github.com
# git add $FILE
# git commit -m "E2e push: $GITHUB_WORKFLOW"
# git push
