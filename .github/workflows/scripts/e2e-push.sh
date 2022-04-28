#!/bin/bash

# We push to main a file e2e/wokflow-name.txt
# with the date inside.

DATE=$(date --utc)
FILE=e2e/$THIS_FILE.txt
COMMIT_MESSAGE="E2e push $GITHUB_WORKFLOW"

if [[ -f "$FILE" ]]; then
  # sha of existing file.
  # content = "what is up, doc?"
  # header = "blob LEN\0"
  # combined = header + content # will be "blob 16\u0000what is up, doc?"
  # sha1 = sha1(combined)

  CONTENT=$(cat "$FILE")
  LEN=$(echo "$CONTENT" | wc -c)
  echo -n "blob $LEN" > HEADER
  dd if=/dev/zero of=HEADER bs=1 count=1 seek=$(stat -c%s HEADER)
  cat HEADER > CONBINED
  echo -n "$CONTENT" >> COMBINED
  SHA=$(cat COMBINED | sha1sum | cut -d " " -f1)
  
  echo existing file with value $CONTENT
  echo existing len $LEN
  echo sha is $SHA

  echo -n $DATE > $FILE

  # Add the file content's sha to the request.
  cat << EOF > DATA
{"message":"$COMMIT_MESSAGE","sha":"$SHA","committer":{"name":"github-actions","email":"github-actions@github.com"},"content":"$(echo -n $DATE | base64 --wrap=0)"}
EOF
  
  # https://docs.github.com/en/rest/repos/contents#create-a-file.
  curl \
    -X PUT \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $GH_TOKEN" \
    https://api.github.com/repos/$GITHUB_REPOSITORY/contents/$FILE \
    -d @DATA
else
  echo $DATE > $FILE

  # https://docs.github.com/en/rest/repos/contents#create-a-file.
  curl \
    -X PUT \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $GH_TOKEN" \
    https://api.github.com/repos/$GITHUB_REPOSITORY/contents/$FILE \
    -d '{"message":"$COMMIT_MESSAGE","committer":{"name":"github-actions","email":"github-actions@github.com"},"content":"$(echo -n $DATE | base64 --wrap=0)"}'
fi



# git config --global user.name github-actions
# git config --global user.email github-actions@github.com
# git add $FILE
# git commit -m "E2e push: $GITHUB_WORKFLOW"
# git push
          
