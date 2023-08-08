#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 provenance_path"
    exit 1
fi

# Script inputs
GITHUB_REF="${GITHUB_REF:-}"
GITHUB_AUTH_TOKEN="${GITHUB_AUTH_TOKEN:-}"

provenance_path="$1"
env=$(jq -r '.dsseEnvelope.payload' <"${provenance_path}" | base64 -d | jq -r '.predicate.buildDefinition.internalParameters')

export_var() {
    local name="$1"
    value=$(echo "${env}" | jq -r ".${name}")
    export "${name}"="${value}"
}

export GH=~/slsa/slsa-github-generator/gh/gh_2.9.0_linux_amd64/bin/gh
export GH_TOKEN=${GITHUB_AUTH_TOKEN}
export BINARY=my-artifact
export PROVENANCE=my-artifact.build.slsa
export THIS_FILE=e2e.delegator-generic.workflow_dispatch.branch1.checkout.slsa3.yml
export BUILDER_ID=https://github.com/slsa-framework/example-trw/.github/workflows/builder_example_slsa3.yml
export BUILDER_TAG=v3.0.0
export SLSA_VERIFIER_TESTING=1

export_var GITHUB_SHA
export_var GITHUB_ACTOR_ID
export_var GITHUB_EVENT_NAME
export_var GITHUB_EVENT_NAME
export_var GITHUB_REF
export_var GITHUB_REF_TYPE
export_var GITHUB_REPOSITORY
export_var GITHUB_REPOSITORY_ID
export_var GITHUB_REPOSITORY_OWNER_ID
export_var GITHUB_RUN_ATTEMPT
export_var GITHUB_RUN_ID
export_var GITHUB_RUN_NUMBER
export_var GITHUB_TRIGGERING_ACTOR_ID
export_var GITHUB_WORKFLOW_REF
export_var GITHUB_WORKFLOW_SHA
GITHUB_REF_NAME=$(echo "${GITHUB_REF}" | cut -d '/' -f3)
export GITHUB_REF_NAME

export CHECKOUT_SHA1=f0afb8daaa59dc649b7c839fc3afce24f319527a
export CHECKOUT_MESSAGE="hello checkout"
