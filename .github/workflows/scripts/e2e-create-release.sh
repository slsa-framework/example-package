
#!/usr/bin/env bash

source "./.github/workflows/scripts/e2e-utils.sh"

SEMVER=$(gh release list -L 1 | cut -f1)
PATCH_METADATA=$(echo "$SEMVER" | cut -d '.' -f3)
PATCH=$(echo "$PATCH_METADATA" | cut -d '-' -f1)
if ! [[ "$PATCH" =~ ^[0-9]+$ ]]; then
    echo "patch ($PATCH) is not a number"
    exit 1
fi

NEW_PATCH=$((PATCH + 1))
MAJOR_MINOR=$(echo "$SEMVER" | cut -d '.' -f1,2)
NEW_SEMVER="$MAJOR_MINOR.$NEW_PATCH"

BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
ECOSYSTEM=$(echo "$THIS_FILE" | cut -d '.' -f2)

cat << EOF > DATA
**E2e release creation**:
Ecosystem: $ECOSYSTEM
Tag: $NEW_SEMVER
Branch: $BRANCH
Commit: $GITHUB_SHA
Caller file: $THIS_FILE
Caller name: $GITHUB_WORKFLOW
EOF

# Note: we use semver's metadata to avoid release collision between tests.
# The semver verification of slsa-verifier for the versioned-tag ignores the metadata.
gh release create "$NEW_SEMVER-$ECOSYSTEM-$BRANCH" --notes-file ./DATA --target "$BRANCH"
