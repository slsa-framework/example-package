#!/bin/bash

set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-utils.sh"

# e2e_update_badge updates a badge in the repo for the given test.
e2e_update_badge() {
    this_file=$(e2e_this_file)
    badge_file="badges/${this_file}.svg"
    message="$1"
    color="$2"

    github_repo="${GITHUB_REPOSITORY:-}"

    # XXX: Need to create a new checkout to authenticate for some reason.
    gh repo clone "${github_repo}" -- -b main
    repo_name=$(echo "${github_repo}" | cut -d '/' -f2)
    cd "./${repo_name}"

    mkdir -p "$(dirname "${badge_file}")"
    curl -s -o "${badge_file}" "https://img.shields.io/badge/${this_file//-/--}-${message//-/--}-${color}?logo=github"

    if [ -n "$(git status --porcelain)" ]; then
        token=${PAT_TOKEN:-${GH_TOKEN:-}}

        git config --global user.name github-actions
        git config --global user.email github-actions@github.com

        # Set the remote url to authenticate using the token.
        git remote set-url origin "https://github-actions:${token}@github.com/${github_repo}.git"

        git add "${badge_file}"
        git commit -m "Update badge: ${badge_file}" "${badge_file}"
        git push origin main

    fi

    cd -
}

e2e_update_badge_passing() {
    e2e_update_badge "passing" "success"
}

e2e_update_badge_failing() {
    e2e_update_badge "failing" "critical"
}
