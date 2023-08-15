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

# NOTE: These must be manually updated.

# BYOB
# export CHECKOUT_SHA1=f0afb8daaa59dc649b7c839fc3afce24f319527a
export CHECKOUT_MESSAGE="Hello world!"
export BINARY=my-artifact
export PROVENANCE=my-artifact.build.slsa

# Maven
# ln -s tmp/target/ .
export EXPECTED_ARTIFACT_OUTPUT="Hello world!"
export PROVENANCE_DIR=./tmp
export POMXML=./e2e/maven/workflow_dispatch/pom.xml

# Global vars.
export GH=~/slsa/slsa-github-generator/gh/gh_2.9.0_linux_amd64/bin/gh
export GH_TOKEN=${GITHUB_AUTH_TOKEN}
export THIS_FILE=e2e.maven.workflow_dispatch.main.default.slsa3.yml
export BUILDER_ID=https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_maven_slsa3.yml
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

