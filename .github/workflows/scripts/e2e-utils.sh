#!/usr/bin/env bash
# Comment out the line below to be able to verify failure of certain commands.
#set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-assert.sh"

# Gets the name of the currently running workflow file.
# Note: this requires GH_TOKEN to be set in the workflows.
export THIS_FILE=""

e2e_this_file() {
    # NOTE: Cache the file name so we don't make repeated calls to the API.
    if [ "${THIS_FILE}" == "" ]; then
        THIS_FILE=$(gh api -H "Accept: application/vnd.github.v3+json" "/repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" | jq -r '.path' | xargs basename)
        export THIS_FILE
    fi

    echo "${THIS_FILE}"
}

# Cache THIS_FILE in main shell process so that it's applied to subshells.
# NOTE: This means that the file is always queried once when e2e-utils is
# sourced.
if [ "${THIS_FILE}" == "" ]; then
    e2e_this_file >>/dev/null
fi

# Gets the name of the "builder" for the e2e test.
e2e_this_builder() {
    e2e_this_file | cut -d '.' -f2
}

# Gets the name of the event for the e2e test.
e2e_this_event() {
    e2e_this_file | cut -d '.' -f3
}

# Gets the name of the branch for the e2e test.
e2e_this_branch() {
    e2e_this_file | cut -d '.' -f4
}

# Gets the name of the branch for the e2e test.
e2e_this_options() {
    e2e_this_file | cut -d '.' -f5
}

# Converter from yaml to JSON.
#sudo apt-get install jc

# File is BODY in current directory.
_create_issue_body() {
    local run_date body_file this_file
    run_date=$(date --utc)
    body_file=$(mktemp)
    this_file=$(e2e_this_file)

    # External inputs
    GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
    GITHUB_REF_NAME=${GITHUB_REF_NAME:-}
    GITHUB_RUN_ID=${GITHUB_RUN_ID:-}
    GITHUB_EVENT_NAME=${GITHUB_EVENT_NAME:-}

    # see https://docs.github.com/en/actions/learn-github-actions/environment-variables
    # https://docs.github.com/en/actions/learn-github-actions/contexts.
    cat <<EOF >"${body_file}"
Repo: https://github.com/${GITHUB_REPOSITORY}/tree/${GITHUB_REF_NAME}
Run: https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}
Workflow file: https://github.com/${GITHUB_REPOSITORY}/tree/main/.github/workflows/${this_file}
Workflow runs: https://github.com/${GITHUB_REPOSITORY}/actions/workflows/${this_file}
Trigger: ${GITHUB_EVENT_NAME}
Branch: ${GITHUB_REF_NAME}
Date: ${run_date}
EOF
    echo "${body_file}"
}

# e2e_npm_package_name outputs the package name for the currently running e2e test.
e2e_npm_package_name() {
    # Convert the test workflow file name to the package name.
    # remove the file extension
    package_name="$(e2e_this_file | rev | cut -d'.' -f2- | rev)"
    has_scope=$(e2e_this_file | cut -d '.' -f5 | grep -v unscoped || true)
    # convert periods to hyphen
    package_name="${package_name//./-}"
    if [[ -n "$has_scope" ]]; then
        package_name="@slsa-framework/${package_name}"
    fi
    echo "${package_name}"
}

# e2e_npm_package_dir prints the subdirectory of the npm package.
e2e_npm_package_dir() {
    # Convert the test workflow file name to the package name.
    # remove the file extension
    package_name="$(e2e_this_file | rev | cut -d'.' -f2- | rev)"
    # convert periods to hyphen
    package_name="${package_name//./-}"
    echo "e2e/nodejs/${package_name}"
}

# name_to_url takes a npm package name and outputs a purl for that package name.
name_to_purl() {
    # Get the raw package name and scope from the output of `npm pack --json`
    # This name is of the form '<scope>/<package name>'
    raw_package_scope=$(echo "$1" | cut -s -d'/' -f1)
    raw_package_name_and_version=$(echo "$1" | cut -s -d'/' -f2)
    if [ "${raw_package_name_and_version}" == "" ]; then
        raw_package_scope=""
        raw_package_name_and_version="$1"
    fi

    raw_package_version=$(echo "${raw_package_name_and_version}" | cut -d'@' -f2)
    raw_package_name=$(echo "${raw_package_name_and_version}" | cut -d'@' -f1)

    # package scope (namespace) is URL(percent) encoded.
    package_scope=$(echo "\"${raw_package_scope}\"" | jq -r '. | @uri')
    # package name is URL(percent) encoded.
    package_name=$(echo "\"${raw_package_name}\"" | jq -r '. | @uri')
    # version is URL(percent) encoded. This is the version from the project's
    # package.json and could be a commit, or any string by the user. It does not
    # actually have to be a version number and is not validated as such by npm.
    package_version=$(echo "\"${raw_package_version}\"" | jq -r '. | @uri')

    package_id="${package_name}@${package_version}"
    if [ "${package_scope}" != "" ]; then
        package_id="${package_scope}/${package_id}"
    fi
    echo "pkg:npm/${package_id}"
}

# strip_zeros strips leading zeros.
strip_zeros() {
    # shellcheck disable=SC2001
    echo "$1" | sed -e 's/0*\([1-9][0-9]*\)/\1/g'
}

# version_major prints the major version number if numeric.
version_major() {
    # sed strips off remaining non-digit text. e.g. v1-rc0 will return 1
    VER=$(strip_zeros "$(echo "${1#"v"}" | cut -d '-' -f1 | cut -s -d '.' -f1 | sed -e 's/^\([0-9]*\).*/\1/g')")
    if [ "$VER" == "" ]; then
        # string may not contain delimiters.
        VER=$(strip_zeros "${1#"v"}" | cut -d '-' -f1 | sed -e 's/^\([0-9]*\).*/\1/g')
    fi
    echo "$VER"
}

# version_minor prints the minor version number if numeric.
version_minor() {
    # sed strips off remaining non-digit text. e.g. v1.2-rc0 will return 2
    strip_zeros "$(echo "${1#"v"}" | cut -d '-' -f1 | cut -s -d '.' -f2 | sed -e 's/^\([0-9]*\).*/\1/g')"
}

# version_patch prints the patch version number if numeric.
version_patch() {
    # sed strips off remaining non-digit text. e.g. v1.3.4-rc0 will return 4
    strip_zeros "$(echo "${1#"v"}" | cut -d '-' -f1 | cut -s -d '.' -f3 | sed -e 's/^\([0-9]*\).*/\1/g')"
}

# version_pre prints the string pre-release portion of the tag if present.
version_pre() {
    echo "${1#"v"}" | cut -s -d '-' -f2
}

# version_rc prints the release candidate version if numeric.
version_rc() {
    # sed strips off remaining non-digit text. e.g. v1.3.4-rc.03abc will return 3
    strip_zeros "$(version_pre "$1" | grep -e '^rc\.[0-9]\+' | sed -e 's/^rc\.\([0-9]*\).*/\1/g')"
}

# version_eq returns 0 if the left-hand version is equal to the right-hand
# version.
# $1: left-hand version string
# $2: right-hand version string
version_eq() {
    # strip 'v' prefix from versions
    local lh=${1#+"v"}
    local rh=${2#+"v"}

    local lh_major lh_minor lh_patch lh_pre lh_rc
    lh_major=$(version_major "$lh")
    lh_minor=$(version_minor "$lh")
    lh_patch=$(version_patch "$lh")
    lh_pre=$(version_pre "$lh")
    lh_rc=$(version_rc "$lh")

    local rh_major rh_minor rh_patch rh_pre rh_rc
    rh_major=$(version_major "$rh")
    rh_minor=$(version_minor "$rh")
    rh_patch=$(version_patch "$rh")
    rh_pre=$(version_pre "$rh")
    rh_rc=$(version_rc "$rh")

    if [ "${rh_major:-0}" -eq "${lh_major:-0}" ] && [ "${rh_minor:-0}" -eq "${lh_minor:-0}" ] && [ "${rh_patch:-0}" -eq "${lh_patch:-0}" ]; then
        if [ "${rh_rc}" != "" ] && [ "${lh_rc}" != "" ]; then
            if [ "${rh_rc}" == "${lh_rc}" ]; then
                return 0
            fi
        else
            if [ "${rh_pre}" == "${lh_pre}" ]; then
                return 0
            fi
        fi
    fi

    return 1
}

# version_gt returns 0 if the left-hand version is greater than the right-handd
# version.
# $1: left-hand version string
# $2: right-hand version string
version_gt() {
    # strip 'v' prefix from versions
    local lh=${1#+"v"}
    local rh=${2#+"v"}

    if [ "$lh" == "$rh" ]; then
        return 1
    fi

    local lh_major lh_minor lh_patch lh_pre lh_rc
    lh_major=$(version_major "$lh")
    lh_minor=$(version_minor "$lh")
    lh_patch=$(version_patch "$lh")
    lh_pre=$(version_pre "$lh")
    lh_rc=$(version_rc "$lh")

    local rh_major rh_minor rh_patch rh_pre rh_rc
    rh_major=$(version_major "$rh")
    rh_minor=$(version_minor "$rh")
    rh_patch=$(version_patch "$rh")
    rh_pre=$(version_pre "$rh")
    rh_rc=$(version_rc "$rh")

    if [ "${lh_pre}" != "" ] || [ "${rh_pre}" != "" ]; then
        if version_eq "${lh_major:-0}.${lh_minor:-0}.${lh_patch:-0}" "${rh_major:-0}.${rh_minor:-0}.${rh_patch:-0}"; then
            # compare pre-release values
            if [ "${lh_rc}" != "" ] && [ "${rh_rc}" != "" ]; then
                if [ "${lh_rc:-0}" -gt "${rh_rc:-0}" ]; then
                    return 0
                else
                    return 1
                fi
            fi

            if [ "${lh_pre}" != "" ] && [ "${rh_pre}" != "" ]; then
                if [[ "${lh_pre}" > "${rh_pre}" ]]; then
                    return 0
                else
                    return 1
                fi
            fi

            # An empty pre-release value is always greater than a pre-release value.
            if [ "${lh_pre}" == "" ]; then
                return 0
            else
                return 1
            fi
        fi
    fi

    if [ "${lh_major:-0}" == "${rh_major:-0}" ]; then
        if version_gt "${lh_minor:-0}.${lh_patch:-0}-${lh_pre}" "${rh_minor:-0}.${rh_patch:-0}-${rh_pre}"; then
            return 0
        fi
    else
        # exit 0 if lh is greater than rh
        if [ "${lh_major:-0}" -gt "${rh_major:-0}" ]; then
            return 0
        fi
    fi

    return 1
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
    local lh=${1#+"v"}
    local rh=${2#+"v"}

    if [ "$lh" == "$rh" ]; then
        return 1
    fi

    local lh_major lh_minor lh_patch lh_pre lh_rc
    lh_major=$(version_major "$lh")
    lh_minor=$(version_minor "$lh")
    lh_patch=$(version_patch "$lh")
    lh_pre=$(version_pre "$lh")
    lh_rc=$(version_rc "$lh")

    local rh_major rh_minor rh_patch rh_pre rh_rc
    rh_major=$(version_major "$rh")
    rh_minor=$(version_minor "$rh")
    rh_patch=$(version_patch "$rh")
    rh_pre=$(version_pre "$rh")
    rh_rc=$(version_rc "$rh")

    if [ "${lh_pre}" != "" ] || [ "${rh_pre}" != "" ]; then
        if version_eq "${lh_major:-0}.${lh_minor:-0}.${lh_patch:-0}" "${rh_major:-0}.${rh_minor:-0}.${rh_patch:-0}"; then
            # compare pre-release values
            if [ "${lh_rc}" != "" ] && [ "${rh_rc}" != "" ]; then
                if [ "${lh_rc:-0}" -lt "${rh_rc:-0}" ]; then
                    return 0
                else
                    return 1
                fi
            fi

            if [ "${lh_pre}" != "" ] && [ "${rh_pre}" != "" ]; then
                if [[ "${lh_pre}" < "${rh_pre}" ]]; then
                    return 0
                else
                    return 1
                fi
            fi

            # An empty pre-release value is always greater than a pre-release value.
            if [ "${rh_pre}" == "" ]; then
                return 0
            else
                return 1
            fi
        fi
    fi

    if [ "${lh_major:-0}" == "${rh_major:-0}" ]; then
        if version_lt "${lh_minor:-0}.${lh_patch:-0}-${lh_pre}" "${rh_minor:-0}.${rh_patch:-0}-${rh_pre}"; then
            return 0
        fi
    else
        # exit 0 if lh is less than rh
        if [ "${lh_major:-0}" -lt "${rh_major:-0}" ]; then
            return 0
        fi
    fi

    return 1
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
    body_file=$(_create_issue_body)

    echo "" >>"${body_file}"
    echo "**Tests are passing now. Closing this issue.**" >>"${body_file}"
    echo "${body_file}"
}

e2e_verify_predicate_subject_name() {
    query=".subject[] | select (.name==\"$2\") | .name"
    _e2e_verify_query "$1" "$2" "${query}"
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

e2e_verify_predicate_metadata_v1() {
    _e2e_verify_query "$1" "$2" '.predicate.runDetails.metadata'
}

e2e_verify_predicate_materials_v1() {
    _e2e_verify_query "$1" "$2" '.predicate.buildDefinition.resolvedDependencies[0]'
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
    e2e_assert_eq "${name}" "${expected}" "${query} should be ${expected} but was ${name}"
}

# Returns the first 2 asset in a release.
e2e_get_release_assets_filenames() {
    local tag="$1"
    assets=$(gh release view --json assets "${tag}" | jq -r '.assets | .[0].name, .[1].name' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    echo "${assets}"
}

# Checks if tag is a prerelease
e2e_is_prerelease() {
    local tag="$1"
    prerelease=$(gh release view "${tag}" --json isPrerelease | jq -r '.isPrerelease')
    echo "${prerelease}"
}

# Checks if tag is a draft
e2e_is_draft() {
    local tag="$1"
    draft=$(gh release view "${tag}" --json isDraft | jq -r '.isDraft')
    echo "${draft}"
}

e2e_verify_predicate_v1_buildDefinition_externalParameters_source() {
    _e2e_verify_query "$1" "$2" '.predicate.buildDefinition.externalParameters.source'
}

e2e_verify_predicate_v1_buildDefinition_buildType() {
    _e2e_verify_query "$1" "$2" '.predicate.buildDefinition.buildType'
}

e2e_verify_predicate_v1_buildDefinition_internalParameters() {
    _e2e_verify_query "$1" "$3" '.predicate.buildDefinition.internalParameters.'"$2"
}

e2e_verify_predicate_v1_runDetails_builder_id() {
    _e2e_verify_query "$1" "$2" '.predicate.runDetails.builder.id'
}

e2e_verify_predicate_v1_runDetails_metadata_invocationId() {
    _e2e_verify_query "$1" "$2" '.predicate.runDetails.metadata.invocationId'
}

e2e_verify_predicate_v1_buildDefinition_externalParameters_workflow() {
    if [[ -z "${BUILDER_INTERFACE_TYPE:-}" ]]; then
        return 0
    fi
    if [[ "${BUILDER_INTERFACE_TYPE}" == "builder" ]]; then
        return 0
    fi

    _e2e_verify_query "$1" "$2" ".predicate.buildDefinition.externalParameters.workflow.path"
    _e2e_verify_query "$1" "$3" ".predicate.buildDefinition.externalParameters.workflow.ref"
    _e2e_verify_query "$1" "$4" ".predicate.buildDefinition.externalParameters.workflow.repository"
}

e2e_verify_predicate_v1_buildDefinition_externalParameters_inputs() {
    _e2e_verify_query "$1" "$2" '.predicate.buildDefinition.externalParameters.inputs'
}

e2e_verify_predicate_v1_buildDefinition_resolvedDependencies() {
    _e2e_verify_query "$1" "$2" '.predicate.buildDefinition.resolvedDependencies'
}

e2e_verify_predicate_v1_buildDefinition_resolvedDependencies0() {
    _e2e_verify_query "$1" "$2" '.predicate.buildDefinition.resolvedDependencies[0]'
}
