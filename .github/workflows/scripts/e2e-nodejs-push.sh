#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# This script bumps the npm package's version number, commits it, and pushes to
# the repository.

branch=$(e2e_this_branch)

# Check presence of file in the correct branch.
gh repo clone "$GITHUB_REPOSITORY" -- -b "$branch"
repo_name=$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f2)
cd ./"$repo_name"

# Use the PAT_TOKEN if one is specified.
# TODO(github.com/slsa-framework/example-package/issues/52): Always use PAT_TOKEN
push_token=${PAT_TOKEN+$PAT_TOKEN}
if [[ -z "$push_token" ]]; then
    echo "Push events cannot be triggered with GH_TOKEN. PAT token is required."
    exit 1
fi

package_dir="$(e2e_npm_package_dir)"

cd "${package_dir}"
# NOTE: npm version patch will not create a git tag if current directory does
# not have a .git directory.
tag=$(npm version patch)
cd -

git config --global user.name github-actions
git config --global user.email github-actions@github.com
git commit -m "${GITHUB_WORKFLOW}" "${package_dir}/package.json" "${package_dir}/package-lock.json"

# Set the remote url to authenticate using the token.
git remote set-url origin "https://github-actions:${push_token}@github.com/${GITHUB_REPOSITORY}.git"

# If this is an e2e test for a tag, then tag the commit.
this_event=$(e2e_this_event)
if [ "${this_event}" == "tag" ]; then
    git tag "${tag}"
    git push origin "${branch}" "${tag}"
else
    git push origin "${branch}"
fi
