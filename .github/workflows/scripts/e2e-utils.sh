#!/usr/bin/env bash
# Comment out the line below to be able to verify failure of certain commands.
#set -euo pipefail

source "./.github/workflows/scripts/e2e-assert.sh"

# Gets the name of the currently running workflow file.
# Note: this requires GH_TOKEN to be set in the workflows.
e2e_this_file() {
    gh api -H "Accept: application/vnd.github.v3+json" "/repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" | jq -r '.path' | cut -d '/' -f3
}

# Converter from yaml to JSON.
#sudo apt-get install jc

# File is BODY in current directory.
_create_issue_body() {
    RUN_DATE=$(date --utc)

    # see https://docs.github.com/en/actions/learn-github-actions/environment-variables
    # https://docs.github.com/en/actions/learn-github-actions/contexts.
    cat <<EOF >BODY
Repo: https://github.com/$GITHUB_REPOSITORY/tree/$GITHUB_REF_NAME
Run: https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID
Workflow name: $GITHUB_WORKFLOW
Workflow file: https://github.com/$GITHUB_REPOSITORY/tree/main/.github/workflows/$THIS_FILE
Trigger: $GITHUB_EVENT_NAME
Branch: $GITHUB_REF_NAME
Date: $RUN_DATE
EOF
}

e2e_create_issue_failure_body() {
    _create_issue_body
}

e2e_create_issue_success_body() {
    _create_issue_body

    echo "" >>./BODY
    echo "**Tests are passing now. Closing this issue.**" >>./BODY

}

e2e_verify_predicate_subject_name() {
    _e2e_verify_query "$1" "$2" '.subject[0].name'
}

e2e_verify_predicate_builder_id() {
    _e2e_verify_query "$1" "$2" '.predicate.builder.id'
}

e2e_verify_predicate_buildType() {
    _e2e_verify_query "$1" "$2" '.predicate.buildType'
}

e2e_verify_predicate_invocation_configSource() {
    _e2e_verify_query "$1" "$2" '.predicate.invocation.configSource'
}

# e2e_verify_predicate_invocation_environment(attestation, env_key, expected)
e2e_verify_predicate_invocation_environment() {
    _e2e_verify_query "$1" "$3" '.predicate.invocation.environment.'"$2"
}

# $1: step number
# $2: the attestation content
# $3: expected value.
e2e_verify_predicate_buildConfig_step_command() {
    _e2e_verify_query "$2" "$3" ".predicate.buildConfig.steps[$1].command[1:]"
}

# $1: step number
# $2: the attestation content
# $3: expected value.
e2e_verify_predicate_buildConfig_step_env() {
    local attestation="$2"
    local expected
    expected="$(echo -n "$3" | jq -c '.| sort')"

    if [[ "${expected}" == "[]" ]]; then
        _e2e_verify_query "${attestation}" "null" ".predicate.buildConfig.steps[$1].env"
    else
        _e2e_verify_query "${attestation}" "${expected}" ".predicate.buildConfig.steps[$1].env | sort"
    fi
}

# $1: step number
# $2: the attestation content
# $3: expected value.
e2e_verify_predicate_buildConfig_step_workingDir() {
    _e2e_verify_query "$2" "$3" ".predicate.buildConfig.steps[$1].workingDir"
}

e2e_verify_predicate_metadata() {
    _e2e_verify_query "$1" "$2" '.predicate.metadata'
}

e2e_verify_predicate_materials() {
    _e2e_verify_query "$1" "$2" '.predicate.materials[0]'
}

# _e2e_verify_query verifies that the result of the given jq query is equal to
# the expected value.
_e2e_verify_query() {
    local attestation="$1"
    local expected="$2"
    local query="$3"
    name=$(echo -n "${attestation}" | jq -c -r "${query}")
    e2e_assert_eq "${name}" "${expected}" "${query} should be ${expected}"
}
