#!/bin/bash

source "./.github/workflows/scripts/e2e-utils.sh"

# e2e_update_badge updates a badge in the repo for the given test.
e2e_update_badge() {
    this_file=$(e2e_this_file)
    badge_file="badges/${this_file}.svg"
    message="$1"
    color="$2"

    mkdir -p "$(dirname "${badge_file}")"
    curl -s -o "${badge_file}" "https://img.shields.io/badge/${this_file//-/--}-${message//-/--}-${color}?logo=github"

    if [ -n "$(git status --porcelain)" ]; then
        git config --global user.name github-actions
        git config --global user.email github-actions@github.com

        git add "${badge_file}"
        git commit -m "Update badge: ${badge_file}" "${badge_file}"
        git push origin main
    fi
}

e2e_update_badge_passing() {
    e2e_update_badge "passing" "success"
}

e2e_update_badge_failing() {
    e2e_update_badge "failing" "critical"
}
