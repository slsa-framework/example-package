#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 run_id output_path"
    exit 1
fi

# Script inputs
GH=${GH:-}

run_id="$1"
output_path="$2"
repo=slsa-framework/example-package

mkdir -p "${output_path}"

artifacts=$($GH api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${repo}/actions/runs/${run_id}/artifacts" |
    jq -r -c '.artifacts')

arr=$(echo "$artifacts" | jq -c '.[]')

for item in ${arr}; do
    artifact_id=$(echo "${item}" | jq -r '.id')
    artifact_name=$(echo "${item}" | jq -r '.name')
    zip_path="${output_path}/${artifact_name}.zip"
    $GH api \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${repo}/actions/artifacts/${artifact_id}/zip" \
        >"${zip_path}"
    echo "Downloaded ${zip_path}"
    unzip -o "${zip_path}" -d "${output_path}"
    rm "${zip_path}"

    # This code is for BYOB debugging.
    if [[ -e "${output_path}/folder.tgz" ]]; then
        cd "${output_path}"
        tar xzvf folder.tgz
        rm folder.tgz
        mv ./*-slsa-attestations/* .
        rmdir ./*-slsa-attestations
        cd -
    fi
done
