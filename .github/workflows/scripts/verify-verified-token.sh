#!/bin/bash -eu
#
# Copyright 2023 SLSA Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

source "./.github/workflows/scripts/e2e-assert.sh"
source "./.github/workflows/scripts/e2e-verify.common.sh"

# Script Inputs
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
GITHUB_REF=${GITHUB_REF:-}
VERIFIED_TOKEN=${VERIFIED_TOKEN:-}
TOOL_REPOSITORY=${TOOL_REPOSITORY:-}
TOOL_REF=${TOOL_REF:-}
PREDICATE=${PREDICATE:-}
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

# Tool information.
echo "VERIFIED_TOKEN: $VERIFIED_TOKEN"
echo "TOOL_REPOSITORY: $TOOL_REPOSITORY"
echo "TOOL_REF: $TOOL_REF"
echo "PREDICATE: $PREDICATE"

e2e_verify_decoded_token "$VERIFIED_TOKEN"

e2e_assert_eq "$TOOL_REPOSITORY" "$GITHUB_REPOSITORY"
e2e_assert_eq "$TOOL_REF" "$GITHUB_REF"

predicate_content=$(<"$PREDICATE")
predicate_content="{\"predicate\": ${predicate_content}}"
echo "PREDICATE_CONTENT: ${predicate_content}"

# Verify common predicate fields.
e2e_verify_common_all_v1 "${predicate_content}"
e2e_verify_predicate_v1_buildDefinition_buildType "${predicate_content}" "https://github.com/slsa-framework/slsa-github-generator/delegator-generic@v0"
e2e_verify_predicate_v1_runDetails_builder_id "${predicate_content}" "https://github.com/$GITHUB_REPOSITORY/.github/workflows/e2e.verify-token.reusable.yml@$GITHUB_REF"
e2e_verify_predicate_v1_buildDefinition_externalParameters_workflow "${predicate_content}" "$(e2e_this_file_full_path)" "$GITHUB_REF" "git+https://github.com/$GITHUB_REPOSITORY"

# Verify external parameters inputs
e2e_verify_predicate_v1_buildDefinition_externalParameters_inputs "${predicate_content}" '{"name1":"value1","name2":"***","name3":"value3","name4":"***","name5":"value5","name6":"***","private-repository":true}'

# Verify resolved dependencies source.
if [[ -n $CHECKOUT_SHA1 ]]; then
    # If the checkout sha was defined, then verify that there is no ref.
    e2e_verify_predicate_v1_buildDefinition_resolvedDependencies "${predicate_content}" "[{\"uri\":\"git+https://github.com/$GITHUB_REPOSITORY\",\"digest\":{\"gitCommit\":\"$CHECKOUT_SHA1\"}}]"
else
    e2e_verify_predicate_v1_buildDefinition_resolvedDependencies "${predicate_content}" "[{\"uri\":\"git+https://github.com/$GITHUB_REPOSITORY@$GITHUB_REF\",\"digest\":{\"gitCommit\":\"$GITHUB_REF\"}}]"
fi
