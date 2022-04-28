#!/bin/bash

# We push to main a file e2e/wokflow-name.txt
# with the date inside.

DATE=$(date --utc)
FILE=e2e/$THIS_FILE.txt
echo $DATE > $FILE

COMMIT_MESSAGE="E2e push $GITHUB_WORKFLOW"

# git config --global user.name github-actions
# git config --global user.email github-actions@github.com
# git add $FILE
# git commit -m "E2e push: $GITHUB_WORKFLOW"
# git push
          
# https://docs.github.com/en/rest/repos/contents#create-a-file.
curl \
  -X PUT \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GH_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPOSITORY/contents/$FILE \
  -d '{"message":"$COMMIT_MESSAGE","committer":{"name":"github-actions","email":"github-actions@github.com"},"content":"$(cat $DATE | base64 --wrap=0)"}'
