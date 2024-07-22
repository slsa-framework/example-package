#!/bin/bash

# With a locally cloned github.com:GoogleCloudPlatform/gke-vsa repository,
# this script veriries all the VSAs within.

do_verify() {
    ATTESTATION_FILE="$1"
    RESOURCE_URI="$2"
    SUBJECT_DIGEST="$3"

    echo "Verifying $ATTESTATION_FILE"

    slsa-verifier verify-vsa \
        --attestation-path "$ATTESTATION_FILE" \
        --resource-uri "$RESOURCE_URI" \
        --subject-digest "$SUBJECT_DIGEST" \
        --verifier-id https://bcid.corp.google.com/verifier/bcid_package_enforcer/v0.1 \
        --public-key-id keystore://76574:prod:vsa_signing_public_key \
        --public-key-path ./vsa_signing_public_key
}

iterate() {
    # find all attestations
    declare -a FILE_PATHS
    while IFS= read -r file; do
        FILE_PATHS+=("$file")
    done < <(find ./gke-node-images:238739202978 ./gke-master-images:78064567238 -type f)

    # development: limit the number of files to verify
    # FILE_PATHS=("${FILE_PATHS[@]:1:3}")

    # parse some the arguments, given the file path
    for FILE_PATH in "${FILE_PATHS[@]}"; do
        DIR=$(dirname "$FILE_PATH")
        DIR_NAME=$(basename "$DIR")
        FILE=$(basename "$FILE_PATH")

        PROJECT_ID=$(echo "$DIR_NAME" | awk -F '[:]' '{print $1}')
        IMAGE_NAME=$(echo "$FILE" | awk -F '(:|\\.intoto\\.jsonl)' '{print $1}')
        IMAGE_ID=$(echo "$FILE" | awk -F '(:|\\.intoto\\.jsonl)' '{print $2}')

        SUBJECT_DIGEST="gce_image_id:$IMAGE_ID"
        RESOURCE_URI="gce_image://$PROJECT_ID:$IMAGE_NAME"

        do_verify "$FILE_PATH" "$RESOURCE_URI" "$SUBJECT_DIGEST"
    done
}

iterate
