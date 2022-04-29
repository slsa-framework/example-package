#!/bin/sh

source "./.github/workflows/scripts/assert.sh"
          
go env -w GOFLAGS=-mod=mod

# Install from HEAD
go install github.com/slsa-framework/slsa-verifier@latest
    
# Default parameters.
RES=$(slsa-verifier --artifact-path ${{ needs.build.outputs.go-binary-name }} --provenance ${{ needs.build.outputs.go-binary-name }}.intoto.jsonl --source github.com/$GITHUB_REPOSITORY)
assert_eq($RES, 0)

# Main branch
RES=$(slsa-verifier --branch main --artifact-path ${{ needs.build.outputs.go-binary-name }} --provenance ${{ needs.build.outputs.go-binary-name }}.intoto.jsonl --source github.com/$GITHUB_REPOSITORY)
assert_eq($RES, 0)

# Wrong branch
RES=$(slsa-verifier --branch not-main --artifact-path ${{ needs.build.outputs.go-binary-name }} --provenance ${{ needs.build.outputs.go-binary-name }}.intoto.jsonl --source github.com/$GITHUB_REPOSITORY)
assert_not_eq($RES, 0)

# Wrong tag
RES=$(slsa-verifier --tag v1.2.3 --artifact-path ${{ needs.build.outputs.go-binary-name }} --provenance ${{ needs.build.outputs.go-binary-name }}.intoto.jsonl --source github.com/$GITHUB_REPOSITORY)
assert_not_eq($RES, 0)

# Wrong versioned-tag
RES=$(slsa-verifier --versioned-tag v1.2.3 --artifact-path ${{ needs.build.outputs.go-binary-name }} --provenance ${{ needs.build.outputs.go-binary-name }}.intoto.jsonl --source github.com/$GITHUB_REPOSITORY)
assert_not_eq($RES, 0)

#TODO: read out the provenance information once we print it
#TODO: previous releases, curl the binary directly. We should list the releases and run all commands automatically