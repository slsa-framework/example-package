#!/bin/bash
set -euo pipefail

git pull --rebase

git branch -D branch1
git checkout -b branch1
git push --set-upstream origin branch1 -f

git checkout main

# Update a dummy file to avoid https://github.com/slsa-framework/example-package/issues/44
echo "$(date)" > ./e2e/dummy
git add ./e2e/dummy
git push