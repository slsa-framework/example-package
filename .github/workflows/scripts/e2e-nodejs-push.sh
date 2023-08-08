#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# This script bumps the npm package's version number, commits it, and pushes to
# the repository.

# Script Inputs
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
GITHUB_WORKFLOW=${GITHUB_WORKFLOW:-}
GITHUB_SHA=${GITHUB_SHA:-}
GH_TOKEN=${GH_TOKEN:-}

branch=$(e2e_this_branch)

# NOTE: We can't simply push from $branch because it is occaisonally reset to
# the main branch. We need to maintain the version number in package.json
# because you cannot overwrite a version in npmjs.com. Instead we commit to main,
# set the tag, reset $branch and push both main and $branch.
gh repo clone "$GITHUB_REPOSITORY" -- -b main
repo_name=$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f2)
cd ./"$repo_name"

git config --global user.name github-actions
git config --global user.email github-actions@github.com

# Set the remote url to authenticate using the token.
git remote set-url origin "https://github-actions:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

package_dir="$(e2e_npm_package_dir)"

cd "${package_dir}"
# NOTE: npm version patch will not create a git tag if current directory does
# not have a .git directory.
tag=$(npm version patch)
cd -

# Commit the new version.
git commit -m "${GITHUB_WORKFLOW}" "${package_dir}/package.json" "${package_dir}/package-lock.json"

# If this is an e2e test for a tag, then tag the commit and push it.
this_event=$(e2e_this_event)
if [ "${this_event}" == "tag" ] || [ "${this_event}" == "create" ]; then
    git tag "${tag}"
fi

if [ "${branch}" != "main" ]; then
    # Reset branch1 and push the new version.
    # git branch -D "$branch"
    git checkout -b "$branch"
    if [ "${this_event}" == "tag" ] || [ "${this_event}" == "create" ]; then
        git push --set-upstream origin "${branch}" "${tag}" -f
    else
        git push --set-upstream origin "$branch" -f
    fi
    git checkout main

    # Update a dummy file to avoid https://github.com/slsa-framework/example-package/issues/44
    date >./e2e/dummy
    git add ./e2e/dummy
    git commit -m "sync'ing branch1 - $(cat ./e2e/dummy)"
    git push origin main
else
    if [ "${this_event}" == "tag" ] || [ "${this_event}" == "create" ]; then
        # TODO(#213): push tag separately until bug is fixed.
        # NOTE: If there is a concurrent update to main we want it to fail here
        # without pushing the tag because we will lose the changes to main.
        git push origin main
        git push origin "${tag}"
    else
        git push origin main
    fi
fi

# If this is a test for a release event, create the release.
if [ "${this_event}" == "release" ]; then
    this_file=$(e2e_this_file)
    data_file=$(mktemp)
    cat <<EOF >"${data_file}"
**E2E release creation**:
Tag: ${tag}
Branch: ${branch}
Commit: ${GITHUB_SHA}
Caller file: ${this_file}
EOF

    gh release create "${tag}" --notes-file "${data_file}" --target "${branch}"
fi

if [ "${this_event}" == "workflow_dispatch" ]; then
    this_file=$(e2e_this_file)
    curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/workflows/${this_file}/dispatches" \
        -d "{\"ref\":\"${branch}\",\"inputs\":{\"trigger_build\": true}}" \
        -H "Authorization: token ${GH_TOKEN}"
fi
