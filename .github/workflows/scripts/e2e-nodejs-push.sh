#!/usr/bin/env bash
set -euo pipefail

set -x

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# This script bumps the npm package's version number, commits it, and pushes to
# the repository.

branch=$(e2e_this_branch)

# NOTE: We can't simply push from $branch because it is occaisonally reset to
# the main branch. We need to maintain the version number in package.json
# because you cannot overwrite a version in npmjs.com. Instead we commit to main,
# set the tag, reset $branch # and # push both main and $branch.
gh repo clone "$GITHUB_REPOSITORY" -- -b main
repo_name=$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f2)
cd ./"$repo_name"

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
push_token=${PAT_TOKEN+$PAT_TOKEN}
if [[ -z "$push_token" ]]; then
    echo "Push events cannot be triggered with GH_TOKEN. PAT token is required."
    exit 1
fi

git config --global user.name github-actions
git config --global user.email github-actions@github.com

# Set the remote url to authenticate using the token.
git remote set-url origin "https://github-actions:${push_token}@github.com/${GITHUB_REPOSITORY}.git"

package_dir="$(e2e_npm_package_dir)"

cd "${package_dir}"
# NOTE: npm version patch will not create a git tag if current directory does
# not have a .git directory.
tag=$(npm version patch)
cd -

git commit -m "${GITHUB_WORKFLOW}" "${package_dir}/package.json" "${package_dir}/package-lock.json"

# If this is an e2e test for a tag, then tag the commit and push it.
this_event=$(e2e_this_event)
if [ "${this_event}" == "tag" ]; then
    git tag "${tag}"
    git push origin "${tag}"
fi

if [ "${branch}" != "main" ]; then
    # Reset branch1 and push the new version.
    # git branch -D "$branch"
    git checkout -b "$branch"
    git push --set-upstream origin "$branch" -f
    git checkout main

    # Update a dummy file to avoid https://github.com/slsa-framework/example-package/issues/44
    date >./e2e/dummy
    git add ./e2e/dummy
    git commit -m "sync'ing branch1 - $(cat ./e2e/dummy)"
fi

git push origin main
