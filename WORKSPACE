workspace(name = "com_github_slsa_framework_example_package")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "bfc5ce70b9d1634ae54f4e7b495657a18a04e0d596785f672d35d5f505ab491a",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.40.0/rules_go-v0.40.0.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.40.0/rules_go-v0.40.0.zip",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "29d5dafc2a5582995488c6735115d1d366fcd6a0fc2e2a153f02988706349825",
    url = "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.31.0/bazel-gazelle-v0.31.0.tar.gz",
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("//:deps.bzl", "go_dependencies")

# gazelle:repository_macro deps.bzl%go_dependencies
go_dependencies()

go_rules_dependencies()

go_register_toolchains(version = "1.20")

gazelle_dependencies()
