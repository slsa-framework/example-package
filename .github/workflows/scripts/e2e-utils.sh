#!/usr/bin/env bash
# Comment out the line below to be able to verify failure of certain commands.
#set -euo pipefail

# shellcheck source=/dev/null
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

# strip_zeros strips leading zeros.
strip_zeros() {
    # shellcheck disable=SC2001
    echo "$1" | sed -e 's/0*\([0-9]\)/\1/g'
}

# version_major prints the major version number if numeric.
version_major() {
    # sed strips off remaining non-digit text. e.g. v1-rc0 will return 1
    VER=$(strip_zeros "$(echo "${1#"v"}" | cut -s -d '.' -f1 | sed -e 's/^\([0-9]*\).*/\1/g')")
    if [ "$VER" == "" ]; then
        # string may not contain delimiters.
        VER=$(strip_zeros "${1#"v"}" | sed -e 's/^\([0-9]*\).*/\1/g')
    fi
    echo "$VER"
}

# version_minor prints the minor version number if numeric.
version_minor() {
    # sed strips off remaining non-digit text. e.g. v1.2-rc0 will return 2
    strip_zeros "$(echo "${1#"v"}" | cut -s -d '.' -f2 | sed -e 's/^\([0-9]*\).*/\1/g')"
}

# version_patch prints the patch version number if numeric.
version_patch() {
    # sed strips off remaining non-digit text. e.g. v1.3.4-rc0 will return 4
    strip_zeros "$(echo "${1#"v"}" | cut -s -d '.' -f3 | sed -e 's/^\([0-9]*\).*/\1/g')"
}

# version_eq returns 0 if the left-hand version is equal to the right-hand
# version.
# $1: left-hand version string
# $2: right-hand version string
version_eq() {
    # strip 'v' prefix from versions
    RH=${1#+"v"}
    LH=${2#+"v"}

    RH_MAJOR=$(version_major "$RH")
    RH_MINOR=$(version_minor "$RH")
    RH_PATCH=$(version_patch "$RH")

    LH_MAJOR=$(version_major "$LH")
    LH_MINOR=$(version_minor "$LH")
    LH_PATCH=$(version_patch "$LH")

    [ "${RH_MAJOR:-0}" -eq "${LH_MAJOR:-0}" ] && [ "${RH_MINOR:-0}" -eq "${LH_MINOR:-0}" ] && [ "${RH_PATCH:-0}" -eq "${LH_PATCH:-0}" ]
}

# version_gt returns 0 if the left-hand version is greater than the right-handd
# version.
# $1: left-hand version string
# $2: right-hand version string
version_gt() {
    # strip 'v' prefix from versions
    RH=${1#+"v"}
    LH=${2#+"v"}

    if [ "$RH" == "$LH" ]; then
        return 1
    fi

    RH_MAJOR=$(version_major "$RH")
    RH_MINOR=$(version_minor "$RH")
    RH_PATCH=$(version_patch "$RH")

    LH_MAJOR=$(version_major "$LH")
    LH_MINOR=$(version_minor "$LH")
    LH_PATCH=$(version_patch "$LH")

    if [ "${RH_MAJOR:-0}" == "${LH_MAJOR:-0}" ]; then
        version_gt "${RH_MINOR:-0}.${RH_PATCH:-0}" "${LH_MINOR:-0}.${LH_PATCH:-0}"
    else
        # return if RH is greater than LH
        [ "${RH_MAJOR:-0}" -gt "${LH_MAJOR:-0}" ]
    fi
}

# version_re returns 0 if the left-hand version is greater than or equal to the
# right-hand version.
# $1: left-hand version string
# $2: right-hand version string
version_ge() {
    version_gt "$1" "$2" || version_eq "$1" "$2"
}

# version_lt returns 0 if the left-hand version is less than the right-hand
# version.
# $1: left-hand version string
# $2: right-hand version string
version_lt() {
    # strip 'v' prefix from versions
    RH=${1#+"v"}
    LH=${2#+"v"}

    if [ "$RH" == "$LH" ]; then
        return 1
    fi

    RH_MAJOR=$(version_major "$RH")
    RH_MINOR=$(version_minor "$RH")
    RH_PATCH=$(version_patch "$RH")

    LH_MAJOR=$(version_major "$LH")
    LH_MINOR=$(version_minor "$LH")
    LH_PATCH=$(version_patch "$LH")

    if [ "${RH_MAJOR:-0}" == "${LH_MAJOR:-0}" ]; then
        version_lt "${RH_MINOR:-0}.${RH_PATCH:-0}" "${LH_MINOR:-0}.${LH_PATCH:-0}"
    else
        # return if RH is greater than LH
        [ "${RH_MAJOR:-0}" -lt "${LH_MAJOR:-0}" ]
    fi
}

# version_le returns 0 if the left-hand version is less than or equal to the
# right-hand version.
# $1: left-hand version string
# $2: right-hand version string
version_le() {
    version_lt "$1" "$2" || version_eq "$1" "$2"
}

# version_range return 0 if if the version is within a given version range
# (inclusive).
# $1: The version to check.
# $2: The minimum version.
# $3: The maximum version.
version_range() {
    version_ge "$1" "$2" && version_le "$1" "$3"
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
