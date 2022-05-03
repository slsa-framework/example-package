#!/usr/bin/env bash

source "./.github/workflows/scripts/e2e-assert.sh"

# Converter from yaml to JSON.
sudo apt-get install jc

if [[ -z "$CONFIG_GILE" ]]; then
    echo "env variable CONFIG_GILE not set"
    exit 2
fi

e2e_verify_predicate_subject_name() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -r '.subject[0].name')
    e2e_assert_eq "$name" "$expected" "subject should be $expected"
}

e2e_verify_predicate_builder_id() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -r '.predicate.builder'.id)
    e2e_assert_eq "$name" "$expected" "builder should be $expected"
}

e2e_verify_predicate_builderType() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -r '.predicate.buildType')
    e2e_assert_eq "$name" "$expected" "builderType should be $expected"
}

e2e_verify_predicate_invocation_configSource() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -c -r '.predicate.invocation.configSource')
    e2e_assert_eq "$name" "$expected" "configSource should be $expected"
}

e2e_verify_predicate_invocation_environment() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -r '.predicate.invocation.environment | .github_actor, .github_sha1, .os, .arch, .github_event_name, .github_ref, .github_ref_type' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    e2e_assert_eq "$name" "$expected" "environment should be $expected"
}

e2e_verify_predicate_buildConfig_command() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -c -r '.predicate.buildConfig.steps[0].command[1:]')
    e2e_assert_eq "$name" "$expected" "command should be $expected"
}

e2e_verify_predicate_buildConfig_env() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -c -r '.predicate.buildConfig.steps[0].env')
    e2e_assert_eq "$name" "$expected" "env should be $expected"
}

e2e_verify_predicate_metadata() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -c -r '.predicate.metadata')
    e2e_assert_eq "$name" "$expected" "metadata should be $expected"
}

e2e_verify_predicate_materials() {
    local provenance="$1"
    local expected="$2"
    name=$(cat $provenance | jq -c -r '.predicate.materials[0]')
    e2e_assert_eq "$name" "$expected" "material should be $expected"
}