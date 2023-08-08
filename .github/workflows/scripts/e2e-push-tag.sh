#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# This script checks for tags matching the semver major version of the
# DEFAULT_VERSION enviornment variable, bumps the version and pushes a new tag.

# Script Inputs
DEFAULT_VERSION=${DEFAULT_VERSION:-}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
GITHUB_WORKFLOW=${GITHUB_WORKFLOW:-}
GH_TOKEN=${GH_TOKEN:-}
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

branch=$(e2e_this_branch)

# Check presence of file in the correct branch.
gh repo clone "$GITHUB_REPOSITORY" -- -b "$branch"
repo_name=$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f2)
cd ./"$repo_name"

default_major=$(version_major "$DEFAULT_VERSION")
if [[ -z "$default_major" ]]; then
    echo "Invalid DEFAULT_VERSION: $DEFAULT_VERSION"
    exit 1
fi

latest_tag=$DEFAULT_VERSION

echo "Listing tags"
while read -r line; do
    tag=$(echo "$line" | cut -f1)
    major=$(version_major "$tag")
    if [ "$major" == "$default_major" ]; then
        echo "  Processing $tag"
        echo "  latest_tag: $latest_tag"
        if version_gt "$tag" "$latest_tag"; then
            echo " INFO: updating to $tag"
            latest_tag="$tag"
        fi
    fi
done <<<"$(gh api --header 'Accept: application/vnd.github.v3+json' --method GET "/repos/$GITHUB_REPOSITORY/git/refs/tags" --paginate | jq -r '.[].ref' | cut -d'/' -f3)"

echo "Latest tag found is $latest_tag"

release_major=$(version_major "$latest_tag")
release_minor=$(version_minor "$latest_tag")
release_patch=$(version_patch "$latest_tag")
new_patch=$((${release_patch:-0} + 1))
new_tag="v${release_major:-$default_major}.${release_minor:-0}.$new_patch"

echo "New release tag used: $new_tag"
echo "Target branch: $branch"

git config --global user.name github-actions
git config --global user.email github-actions@github.com

# Set the remote url to authenticate using the token.
git remote set-url origin "https://github-actions:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

text_file=e2e/$(e2e_this_file).txt
date --utc >"${text_file}"

git add "${text_file}"
git commit -m "${GITHUB_WORKFLOW}" "${text_file}"

git tag "${new_tag}"
git push origin "${branch}" "${new_tag}"
