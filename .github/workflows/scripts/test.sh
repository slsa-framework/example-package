#!/usr/bin/env bash
set -euo pipefail

# verify_provenance() {
#     local verifier="$1"
#     local version="$2"
#     echo "$verifier"
#     echo "$version"
# }

# verify_provenance "slsa-verifier" "v0.0.1"

# THIS_FILE=e2e.go.tag.main.config-ldflags-assets.slsa3.yml

# echo $GH
# RELEASE_LIST=$($GH release -L 200 list)
# echo "list: $RELEASE_LIST"
# PATCH="0"
# while read -r line; do
#     TAG=$(echo "$line" | cut -f1)
#     BODY=$($GH release view "$TAG" --json body | jq -r '.body')
#     echo "$TAG"
#     if [[ "$BODY" == *"$THIS_FILE"* ]]; then
#         # We only bump the patch, so we need not verify major/minor.
#         P=$(echo "$TAG" | cut -d '.' -f3)
#         if ! [[ "$P" =~ ^[0-9]+$ ]]; then
#             continue
#         fi
#         echo "  Processing $TAG"
#         echo "  P: $P"
#         echo "  PATCH: $PATCH"
#         echo "  RELEASE_TAG: $RELEASE_TAG"
#         if [[ "$P" -gt "$PATCH" ]]; then
#             echo " INFO: updating to $TAG"
#             PATCH="$P"
#             RELEASE_TAG="$TAG"
#         fi
#     fi
# done <<<"$RELEASE_LIST"

# _e2e_verify_query() {
#     local attestation="$1"
#     local expected="$2"
#     local query="$3"
#     name=$(echo -n "${attestation}" | jq -c -r "${query}")
#     echo "${name}" "${expected}" "${query} should be ${expected}"
# }

# e2e_verify_predicate_subject_name() {
#     query=".subject[] | select (.name==\"$2\") | .name"
#     _e2e_verify_query "$1" "$2" "${query}"
# }

# e2e_verify_predicate_subject_name "$1" "$2"
# strip_zeros strips leading zeros.
# source "./.github/workflows/scripts/e2e-utils.sh"

this_file="e2e.generic.tag.main.bla.slsa3.yml"
annotated_tags=$(echo "$this_file" | cut -d '.' -f5 | grep annotated || true)
is_annotated_tag=$([ -n "$annotated_tags" ] && echo "yes" || echo "no")
echo "$is_annotated_tag"
# latest_tag=v26.0.0
# default_major="26"
# if [[ -n "$annotated_tags" ]]; then
#     echo "Listing annotated tags"
#     tag_list=$(git tag -l "v$default_major*")
#     while read -r line; do
#         tag="$line"
#         major=$(version_major "$tag")
#         if [ "$major" == "$default_major" ]; then
#             echo "  Processing $tag"
#             echo "  latest_tag: $latest_tag"
#             if version_gt "$tag" "$latest_tag"; then
#                 echo " INFO: updating to $tag"
#                 latest_tag="$tag"
#             fi
#         fi
#     done <<<"$tag_list"
# fi
