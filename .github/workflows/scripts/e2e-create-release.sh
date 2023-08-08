#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# Script Inputs
GH_TOKEN=${GH_TOKEN:-}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
GITHUB_ACTOR=${GITHUB_ACTOR:-}
GITHUB_OUTPUT=${GITHUB_OUTPUT:-}
DEFAULT_VERSION=${DEFAULT_VERSION:-}
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

this_file=$(e2e_this_file)
annotated_tags=$(echo "${this_file}" | cut -d '.' -f5 | grep annotated || true)
echo "annotated_tags: ${annotated_tags}"

# List the releases and find the latest for THIS_FILE.
default_major=$(version_major "${DEFAULT_VERSION}")
if [[ -z "${default_major}" ]]; then
    echo "Invalid DEFAULT_VERSION: ${DEFAULT_VERSION}"
    exit 1
fi

prerelease=$(echo "${this_file}" | cut -d '.' -f5 | grep prerelease || true)
echo "prerelease: ${prerelease}"
draft=$(echo "${this_file}" | cut -d '.' -f5 | grep draft || true)
echo "draft: ${draft}"

# Here we find the latest version with the major version equal to that of
# DEFAULT_VERSION.
latest_tag="${DEFAULT_VERSION}"

if [[ -n "${annotated_tags}" ]]; then
    # Check the annotated tags.
    echo "Listing annotated tags"
    repository_name=$(echo "${GITHUB_REPOSITORY}" | cut -d '/' -f2)
    git clone "https://${GITHUB_ACTOR}:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    cd "${repository_name}" || exit 2
    tag_list=$(git tag -l "v${default_major}*")
    while read -r line; do
        tag="${line}"
        major=$(version_major "${tag}")
        if [ "${major}" == "${default_major}" ]; then
            echo "  Processing ${tag}"
            echo "  latest_tag: ${latest_tag}"
            if version_gt "$tag" "${latest_tag}"; then
                echo " INFO: updating to ${tag}"
                latest_tag="${tag}"
            fi
        fi
    done <<<"${tag_list}"
else
    # Check the releases.
    echo "Listing releases"
    while read -r line; do
        tag=$(echo "${line}" | cut -f1)
        major=$(version_major "${tag}")
        if [ "${major}" == "${default_major}" ]; then
            echo "  Processing ${tag}"
            echo "  latest_tag: ${latest_tag}"
            if version_gt "${tag}" "${latest_tag}"; then
                echo " INFO: updating to ${tag}"
                latest_tag="${tag}"
            fi
        fi
    done <<<"$(gh api --header 'Accept: application/vnd.github.v3+json' --method GET "/repos/${GITHUB_REPOSITORY}/releases" --paginate | jq -r '.[].tag_name')"
fi

echo "Latest tag found is ${latest_tag}"

release_major=$(version_major "${latest_tag}")
release_minor=$(version_minor "${latest_tag}")
release_patch=$(version_patch "${latest_tag}")
new_patch=$((${release_patch:-0} + 1))
tag="v${release_major:-$default_major}.${release_minor:-0}.$new_patch"

branch=$(echo "$this_file" | cut -d '.' -f4)

echo "New release tag used: ${tag}"
echo "Target branch: ${branch}"

is_annotated_tag=$([ -n "${annotated_tags}" ] && echo "yes" || echo "no")

data_file=$(mktemp)

cat <<EOF >"${data_file}"
**E2E release creation**:
Tag: ${tag}
Branch: ${branch}
Commit: ${GITHUB_SHA}
Caller file: ${this_file}
Annotated tag: ${is_annotated_tag}
EOF

if [[ -n "${annotated_tags}" ]]; then
    git config user.name "${GITHUB_ACTOR}"
    git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
    git tag -a "${tag}" -F "${data_file}"
    git remote set-url origin "https://${GITHUB_ACTOR}:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    git push origin "${tag}"
else
    # We must use a PAT here in order to trigger subsequent workflows.
    # See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
    if [[ -n "${prerelease}" ]]; then
        gh release create "${tag}" --notes-file "${data_file}" --target "${branch}" --prerelease
    elif [[ -n "${draft}" ]]; then
        # Creating a draft release does not create a tag so we need to create
        # the tag instead to trigger the e2e workflow.
        git config user.name "${GITHUB_ACTOR}"
        git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
        git tag "$tag"
        git remote set-url origin "https://${GITHUB_ACTOR}:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
        # Force push the tag since it may have already been created by a
        # previous failed run of the test.
        git push origin "${tag}" -f
    else
        gh release create "${tag}" --notes-file "${data_file}" --target "${branch}"
    fi
fi

echo "tag=${tag}" >>"${GITHUB_OUTPUT}"
