#!/usr/bin/env bash

set -euo pipefail

# e2e-bootstrap.sh
################################################################################
#
# This script boostraps a e2e test when run via a schedule or workflow_dispatch
# by triggering an event of the desired types (e.g. push (tag or branch),
# workflow_dispatch, # create, release, etc.)
#
# For nodejs tests the corresponding package's version is bumped and the change
# to package.json is updated.
#
# For push events (tag or branch) the e2e/<workflow-name>.txt file is updated,
# committed, and pushed.
#
# For release events a release is created with the corresponding tag.
#
# This script should handle creating push to branch, push to tag, create,
# release, and workflow_dispatch events from either workflow_dispatch or
# schedule events.
#
################################################################################

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# Script Inputs
DEFAULT_VERSION=${DEFAULT_VERSION:-}
GH_TOKEN=${GH_TOKEN:-}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
GITHUB_EVENT_NAME=${GITHUB_EVENT_NAME:-}
GITHUB_WORKFLOW=${GITHUB_WORKFLOW:-}
GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-}
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

# bump_npm_package_version bumps the given npm package's patch version,
# commits it to the local git repo, and outputs the resulting version.
npm_bump_package_version() {
    (
        # NOTE: Make sure -e is always set for this function.
        set -euo pipefail

        local package_dir
        local this_event
        local version
        package_dir="$(e2e_npm_package_dir)"
        this_event="$(e2e_this_event)"

        cd "${package_dir}"
        # NOTE: npm version patch will not create a git tag if current directory does
        # not have a .git directory.
        version="$(npm version patch)"
        cd - &>/dev/null

        git add "${package_dir}/package.json" "${package_dir}/package-lock.json" &>/dev/null

        echo "${version}"
    )
}

# get_latest_tag outputs the latest release version with the same major version
# as DEFAULT_VERSION + 1 patch version.
get_latest_tag() {
    (
        # NOTE: Make sure -e is always set for this function.
        set -euo pipefail

        local latest_tag=$DEFAULT_VERSION
        local tag
        local major
        local default_major

        default_major=$(version_major "${DEFAULT_VERSION}")
        if [[ -z "${default_major}" ]]; then
            echo >&2 "Invalid DEFAULT_VERSION: ${DEFAULT_VERSION}"
            exit 1
        fi

        while read -r line; do
            tag=$(echo "${line}" | cut -f1)
            major=$(version_major "$tag")
            if [ "${major}" == "${default_major}" ]; then
                if version_gt "${tag}" "${latest_tag}"; then
                    latest_tag="${tag}"
                fi
            fi
        done <<<"$(gh api --header 'Accept: application/vnd.github.v3+json' --method GET "/repos/${GITHUB_REPOSITORY}/git/refs/tags" --paginate | jq -r '.[].ref' | cut -d'/' -f3)"

        release_major=$(version_major "$latest_tag")
        release_minor=$(version_minor "$latest_tag")
        release_patch=$(version_patch "$latest_tag")
        new_patch=$((${release_patch:-0} + 1))
        new_tag="v${release_major:-$default_major}.${release_minor:-0}.$new_patch"

        echo "${new_tag}"
    )
}

this_file=$(e2e_this_file)
this_branch=$(e2e_this_branch)
this_builder=$(e2e_this_builder)
this_event=$(e2e_this_event)

# tag_and_push checks out the repository, updates package versions (if
# necessary), creates tags (if necessary), creates a new commit and pushes it to
# the repository. It then echos the tag that was pushed.
#
# We wrap this logic in a function so we can retry it a few times in case there
# was a concurrent push.
tag_and_push() {
    (
        set -euo pipefail

        local tag
        local log_file="$1"

        if [ -z "${log_file}" ]; then
            log_file="/dev/null"
        fi

        {
            # cleanup in case we are retrying
            cd "${GITHUB_WORKSPACE}"
            rm -rf repo_checkout

            # NOTE: We can't simply push from $branch because it is occasionally reset to
            # the main branch. We need to maintain the version number in package.json
            # because you cannot overwrite a version in npmjs.com. Instead we commit to main,
            # set the tag, reset $branch and push both main and $branch.
            gh repo clone "${GITHUB_REPOSITORY}" repo_checkout -- -b main
            cd repo_checkout

            git config --global user.name github-actions
            git config --global user.email github-actions@github.com

            # Set the remote url to authenticate using the token.
            # NOTE: We must use a PAT here in order to trigger subsequent workflows.
            # See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
            # API ref: https://docs.github.com/en/rest/repos/contents#create-a-file.
            git remote set-url origin "https://github-actions:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

            if [ "${this_builder}" == "nodejs" ]; then
                tag="$(npm_bump_package_version)"
            else
                if [ "${this_event}" == "tag" ] || [ "${this_event}" == "create" ] || [ "${this_event}" == "release" ]; then
                    tag="$(get_latest_tag)"
                fi
            fi

            # NOTE: push event "tag" is push to tag, "push" is push to branch
            if [ "${this_event}" == "tag" ] || [ "${this_event}" == "push" ]; then
                # NOTE: For push events we will make a change to the file below and push it.
                # This allows us to filter on this file later.
                file_to_commit=e2e/${this_file}.txt
                echo -n "$(date --utc)" >"${file_to_commit}"
                git add "${file_to_commit}"
            fi

            # Check if there are changes to commit.
            if [ "$(git status --porcelain)" != "" ]; then
                # Commit the changes made so far with a commit message equal to the workflow
                # name.
                git commit -am "${GITHUB_WORKFLOW}"
            fi

            # Create the tag locally.
            if [ "${tag}" != "" ]; then
                git tag "${tag}"
            fi

            # Now we need to push any changes we have made.
            if [ "${this_branch}" == "main" ]; then
                if [ "${this_event}" == "tag" ] || [ "${this_event}" == "create" ] || [ "${this_event}" == "release" ]; then
                    # TODO(#213): push tag separately until bug is fixed.
                    # NOTE: If there is a concurrent update to main we want it to fail here
                    # without pushing the tag because we will lose the changes to main.
                    git push origin main
                    git push origin "${tag}"
                else
                    git push origin main
                fi
            else
                # Reset branch and push the new version.
                # NOTE: we haven't pulled the branch locally so we need to create it.
                git checkout -b "${this_branch}"
                if [ "${this_event}" == "tag" ] || [ "${this_event}" == "create" ] || [ "${this_event}" == "release" ]; then
                    git push --set-upstream origin "${this_branch}" "${tag}" -f
                else
                    git push --set-upstream origin "${this_branch}" -f
                fi
                git checkout main

                # Update a dummy file to avoid branch mismatches.
                # See: https://github.com/slsa-framework/example-package/issues/44
                date >./e2e/dummy
                git add ./e2e/dummy
                git commit -m "sync'ing branch1 - $(cat ./e2e/dummy)"
                git push origin main
            fi
        } &>>"${log_file}"

        echo "${tag}"
    )
}

# Retry tag_and_push up to 5 times in case there are concurrent pushes to the
# repo.
attempt=1
max_attempts=5
tag=""
while true; do
    echo "Creating new commit and pushing, attempt ${attempt}"
    # NOTE: Set +e so that the entire script isn't exited if tag_and_push
    # fails.
    set +e
    log_file=$(mktemp)
    tag=$(tag_and_push "${log_file}")
    tag_and_push_result="$?"
    set -e

    # Write the log file output so it can be seen in the GitHub Actions logs.
    cat "${log_file}"

    # NOTE: We check $? rather than using `if tag_and_push` because the if
    # conditional causes bash to always ignore the '-e' bash option.
    if [[ "${tag_and_push_result}" == "0" ]]; then
        break
    fi

    # Add a bit of jitter to space out retries.
    jitter=$((RANDOM % 6)) # Random number 0 - 5
    sleep $((10 + jitter))
    ((attempt += 1))

    if [ ${attempt} -gt ${max_attempts} ]; then
        echo >&2 "Max retries exceeded!"
        exit 1
    fi
done

# If this is a test for a release event, create the release.
if [ "${this_event}" == "release" ]; then
    data_file=$(mktemp)
    cat <<EOF >"${data_file}"
**E2E release creation**:
Tag: ${tag}
Branch: ${this_branch}
Caller file: ${this_file}
EOF

    gh release create "${tag}" --notes-file "${data_file}" --target "${this_branch}"
fi

# If this is a test for workflow_dispatch, then dispatch the workflow. We may
# have been triggered by a "schedule" event, for example.
if [ "${this_event}" == "workflow_dispatch" ]; then
    curl -s -X POST -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/workflows/${this_file}/dispatches" \
        -d "{\"ref\":\"${this_branch}\",\"inputs\":{\"trigger_build\": true}}" \
        -H "Authorization: token ${GH_TOKEN}"
fi
