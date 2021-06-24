# Example project for SLSA

Example project builds a simple binary using a variety of [SLSA]-compliant
builders.

The code is built using `bazelisk build`:

*   Bazelisk reads [.bazelversion], fetches the correct version of Bazel, and
    then runs `bazel build`.
*   Bazel reads [WORKSPACE], fetches the rules_go module, and then compiles the
    `hello` binary.

For GitHub Actions-based builds, the artifact is uploaded using
[actions/upload-artifact].

[.bazelversion]: .bazelversion
[SLSA]: https://slsa.dev
[WORKSPACE]: WORKSPACE
[actions/upload-artifact]: https://github.com/actions/upload-artifact

## Builders

*   [github-actions-demo.yaml](.github/workflows/github-actions-demo.yaml)
    ([results](https://github.com/slsa-framework/example-package/actions/workflows/github-actions-demo.yaml)):
    SLSA 1 provenance generated on GitHub Actions using
    https://github.com/slsa-framework/github-actions-demo.
*   [slsa-github-generator.yaml](.github/workflows/slsa-github-generator.yaml)
    ([results](https://github.com/slsa-framework/example-package/actions/workflows/slsa-github-generator.yaml)):
    SLSA 2 provenance generated on GitHub Actions using
    https://github.com/slsa-framework/slsa-github-generator.
