#!/bin/bash

source "./.github/workflows/scripts/e2e-utils.sh"

# e2e_update_badge updates a badge in the repo for the given test.
e2e_update_badge() {
    this_file=$(e2e_this_file)
    badge_file="badges/${this_file}.svg"
    message="$1"
    color="$2"

    mkdir -p "$(dirname "${badge_file}")"
    curl -s -O "${badge_file}" "https://img.shields.io/badge/${this_file//-/--}-${message//-/--}-${color}?logo=github&style=plastic"

    if [ -n "$(git status --porcelain)" ]; then
        token=${PAT_TOKEN+$PAT_TOKEN}
        if [[ -z "${token}" ]]; then
            token="${GH_TOKEN}"
        fi

        git config --global user.name github-actions
        git config --global user.email github-actions@github.com
        # Set the remote url to authenticate using the token.
        git remote set-url origin "https://github-actions:${token}@github.com/${GITHUB_REPOSITORY}.git"

        git commit -m "Update badge" "${badge_file}"
        git push origin main
    fi
}

e2e_update_badge_passing() {
    e2e_update_badge "passing" "green"
}

e2e_update_badge_failing() {
    e2e_update_badge "failing" "red"
}
