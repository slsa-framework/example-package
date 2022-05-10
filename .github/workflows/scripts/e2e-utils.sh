#!/usr/bin/env bash

source "./.github/workflows/scripts/e2e-assert.sh"

# Converter from yaml to JSON.
#sudo apt-get install jc

if [[ -z "$CONFIG_FILE" ]]; then
    echo "env variable CONFIG_FILE not set"
    exit 2
fi

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

e2e_verify_predicate_builderType() {
    _e2e_verify_query "$1" "$2" '.predicate.buildType'
}

e2e_verify_predicate_invocation_configSource() {
    _e2e_verify_query "$1" "$2" '.predicate.invocation.configSource'
}

# e2e_verify_predicate_invocation_environment(attestation, expected, env_key)
e2e_verify_predicate_invocation_environment() {
    _e2e_verify_query "$1" "$2" '.predicate.invocation.environment.'"$3"
}

e2e_verify_predicate_buildConfig_command() {
    _e2e_verify_query "$1" "$2" '.predicate.buildConfig.steps[0].command[1:]'
}

e2e_verify_predicate_buildConfig_env() {
    local attestation="$1"
    local expected
    expected=$(echo -n "$2" | jq -c '.| sort')
    _e2e_verify_query "${attestation}" "${expected}" '.predicate.buildConfig.steps[0].env | sort'
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
