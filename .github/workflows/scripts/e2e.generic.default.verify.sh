#!/usr/bin/env bash

source "./.github/workflows/scripts/e2e-verify.common.sh"

go env -w GOFLAGS=-mod=mod

verify_provenance() {
    local verifier="$1"

    # Default parameters.
    if [[ "$BRANCH" == "main" ]]; then
        $verifier --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "main default parameters"
    else
        $verifier --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "not main default parameters"
    fi

    # Correct branch
    $verifier --branch "$BRANCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_eq "$?" "0" "should be branch $BRANCH"

    # Wrong branch
    $verifier --branch "not-$GITHUB_REF_NAME" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong branch"

    # Wrong tag
    $verifier --tag v1.2.3 --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
    e2e_assert_not_eq "$?" "0" "wrong tag"

    if [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
        #TODO: try several versioned-tags and tags.
        SEMVER="$GITHUB_REF_NAME"
        PATCH=$(echo "$SEMVER" | cut -d '.' -f3)
        MINOR=$(echo "$SEMVER" | cut -d '.' -f2)
        MAJOR=$(echo "$SEMVER" | cut -d '.' -f1)

        M="${MAJOR:1}"
        MAJOR_LESS_ONE="v$((M - 1))"
        MINOR_LESS_ONE=$((MINOR - 1))
        PATCH_LESS_ONE=$((PATCH - 1))
        MAJOR_PLUS_ONE="v$((M + 1))"
        MINOR_PLUS_ONE=$((MINOR + 1))
        PATCH_PLUS_ONE=$((PATCH + 1))

        # Correct vM.N.P
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR.$MINOR.$PATCH versioned-tag vM.N.P ($MAJOR.$MINOR.$PATCH) should be correct"

        # Correct vM.N
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR.$MINOR versioned-tag vM.N ($MAJOR.$MINOR) should be correct"

        # Correct vM
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_eq "$?" "0" "$MAJOR versioned-tag vm ($MAJOR) should be correct"

        # Incorrect v(M-1)
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE versioned-tag should be incorrect"

        # Incorrect v(M-1).N
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_LESS_ONE.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR versioned-tag should be incorrect"

        # Incorrect v(M-1).N.P
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_LESS_ONE.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_LESS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.(N-1)
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE versioned-tag should be incorrect"

        # Incorrect vM.(N-1).P
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR_LESS_ONE.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_LESS_ONE.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.N.(P-1)
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR.$PATCH_LESS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_LESS_ONE versioned-tag should be incorrect"

        # Incorrect v(M+1)
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE versioned-tag should be incorrect"

        # Incorrect v(M+1).N
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_PLUS_ONE.$MINOR" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR versioned-tag should be incorrect"

        # Incorrect v(M+1).N.P
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR_PLUS_ONE.$MINOR.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR_PLUS_ONE.$MINOR.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.(N+1)
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE versioned-tag should be incorrect"

        # Incorrect vM.(N+1).P
        slsa-verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR_PLUS_ONE.$PATCH" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR_PLUS_ONE.$PATCH versioned-tag should be incorrect"

        # Incorrect vM.N.(P+1)
        $verifier --branch "$BRANCH" --versioned-tag "$MAJOR.$MINOR.$PATCH_PLUS_ONE" --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "$MAJOR.$MINOR.$PATCH_PLUS_ONE versioned-tag should be incorrect"
    else
        # Wrong versioned-tag
        $verifier --branch "$BRANCH" --versioned-tag v1.2.3 --artifact-path "$BINARY" --provenance "$PROVENANCE" --source "github.com/$GITHUB_REPOSITORY"
        e2e_assert_not_eq "$?" "0" "wrong versioned-tag"
    fi

    # Provenance content verification.
    ATTESTATION=$(jq -r '.payload' <"$PROVENANCE" | base64 -d)

    # Verify all common provenance fields.
    e2e_verify_common_all "$ATTESTATION"

    e2e_verify_predicate_subject_name "$ATTESTATION" "$BINARY"
    e2e_verify_predicate_builder_id "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_buildType "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator@v1"
}

THIS_FILE=$(e2e_this_file)
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
echo "branch is $BRANCH"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is $THIS_FILE"

e2e_run_verifier_all_releases verify_provenance
