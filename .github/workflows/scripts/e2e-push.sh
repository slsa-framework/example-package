#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# We push to main a file e2e/wokflow-name.txt
# with the date inside, to be sure the file is different.

# Script Inputs
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
GITHUB_WORKFLOW=${GITHUB_WORKFLOW:-}
GH_TOKEN=${GH_TOKEN:-}
SHA=${SHA:-}

current_date=$(date --utc)
txt_file=e2e/$(e2e_this_file).txt
commit_message="${GITHUB_WORKFLOW}"
this_branch=$(e2e_this_branch)

# Check presence of file in the correct branch.
gh repo clone "${GITHUB_REPOSITORY}" -- -b "${this_branch}"
repository_name=$(echo "${GITHUB_REPOSITORY}" | cut -d '/' -f2)
cd ./"${repository_name}"

if [ -f "${txt_file}" ]; then
    echo "DEBUG: file ${txt_file} exists on branch ${this_branch}"

    SHA=$(curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/${txt_file}?ref=${this_branch}" | jq -r '.sha')
    if [[ -z "$SHA" ]]; then
        echo "SHA is empty"
        exit 4
    fi

    echo -n "${current_date}" >"${txt_file}"

    # Add the file content's sha to the request.
    data_file=$(mktemp)
    cat <<EOF >"${data_file}"
{"branch":"${this_branch}","message":"${commit_message}","sha":"$SHA","committer":{"name":"github-actions","email":"github-actions@github.com"},"content":"$(echo -n "${current_date}" | base64 --wrap=0)"}
EOF

    # We must use a PAT here in order to trigger subsequent workflows.
    # See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
    # API ref: https://docs.github.com/en/rest/repos/contents#create-a-file.
    curl -s \
        -X PUT \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${GH_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/${txt_file}" \
        -d "@${data_file}"
else
    echo "${current_date}" >"${txt_file}"

    echo "DEBUG: file ${txt_file} does not exist on branch ${this_branch}"

    # We must use a PAT here in order to trigger subsequent workflows.
    # See: https://github.community/t/push-from-action-does-not-trigger-subsequent-action/16854
    # API ref: https://docs.github.com/en/rest/repos/contents#create-a-file.
    curl -s \
        -X PUT \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${GH_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/${txt_file}" \
        -d "{\"branch\":\"${this_branch}\",\"message\":\"${commit_message}\",\"committer\":{\"name\":\"github-actions\",\"email\":\"github-actions@github.com\"},\"content\":\"$(echo -n "${current_date}" | base64 --wrap=0)\"}"
fi

# git config --global user.name github-actions
# git config --global user.email github-actions@github.com
# git add $FILE
# git commit -m "E2e push: $GITHUB_WORKFLOW"
# git push
