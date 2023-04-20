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
    push_token=$GH_TOKEN
fi

package_dir="$(e2e_npm_package_dir)"

cd "${package_dir}"
npm version patch --no-git-tag-version
cd -

git commit -m "${GITHUB_WORKFLOW}" "${package_dir}/package.json" "${package_dir}/package-lock.json"
git config --global user.name github-actions
git config --global user.email github-actions@github.com
git remote set-url origin "https://github-actions:${push_token}@github.com/${GITHUB_REPOSITORY}.git"
git push origin main
