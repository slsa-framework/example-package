# Example project for SLSA

Example project builds a simple binary using a variety of [SLSA]-compliant
builders.

The code is built using `bazelisk build`:

- Bazelisk reads [.bazelversion], fetches the correct version of Bazel, and
  then runs `bazel build`.
- Bazel reads [WORKSPACE], fetches the rules_go module, and then compiles the
  `hello` binary.

For GitHub Actions-based builds, the artifact is uploaded using
[actions/upload-artifact].

[.bazelversion]: .bazelversion
[SLSA]: https://slsa.dev
[WORKSPACE]: WORKSPACE
[actions/upload-artifact]: https://github.com/actions/upload-artifact

## Builders

- [github-actions-demo.yaml](.github/workflows/github-actions-demo.yaml)
  ([results](https://github.com/slsa-framework/example-package/actions/workflows/github-actions-demo.yaml)):
  SLSA 1 provenance generated on GitHub Actions using
  https://github.com/slsa-framework/github-actions-demo.
- [slsa-github-generator.yaml](.github/workflows/slsa-github-generator.yaml)
  ([results](https://github.com/slsa-framework/example-package/actions/workflows/slsa-github-generator.yaml)):
  SLSA 2 provenance generated on GitHub Actions using
  https://github.com/slsa-framework/slsa-github-generator.

## slsa-github-generator e2e test status

### Project health

[![golangci-lint](https://github.com/slsa-framework/example-package/actions/workflows/pre-submit.golangci-lint.yml/badge.svg)](https://github.com/slsa-framework/example-package/actions/workflows/pre-submit.golangci-lint.yml) [![shellcheck](https://github.com/slsa-framework/example-package/actions/workflows/pre-submit.shellcheck.yml/badge.svg)](https://github.com/slsa-framework/example-package/actions/workflows/pre-submit.shellcheck.yml) [![yamllint](https://github.com/slsa-framework/example-package/actions/workflows/pre-submit.yamllint.yml/badge.svg)](https://github.com/slsa-framework/example-package/actions/workflows/pre-submit.yamllint.yml) [![actionlint](https://github.com/slsa-framework/example-package/actions/workflows/pre-submit.actionlint.yml/badge.svg)](https://github.com/slsa-framework/example-package/actions/workflows/pre-submit.actionlint.yml)

### Node.js builder e2e tests

<table>
  <thead>
    <tr>
      <th>Event</th>
      <th>Name</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>create</td>
      <td></td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.create.main.default.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.create.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.create.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td rowspan="8">push</td>
      <td>default branch</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.default.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.push.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>custom publish</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.custom_publish.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.push.main.custom_publish.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.custom_publish.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>Node 16</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.node16.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.push.main.node16.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.node16.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>Node 18</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.node18.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.push.main.node18.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.node18.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>npm dist-tag</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.disttag.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.push.main.disttag.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.main.disttag.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>non-default branch</td>
      <td></td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.branch1.default.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.push.branch1.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.push.branch1.default.slsa3.yml/badge.svg?branch=branch1&event=push" /></a></td>
    </tr>
    <tr>
      <td>push to tag</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.tag.main.default.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.tag.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.tag.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>push to tag (unscoped package)</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.tag.main.unscoped.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.tag.main.unscoped.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.tag.main.unscoped.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>release</td>
      <td></td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.release.main.default.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.release.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.release.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>workflow_dispatch</td>
      <td></td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.workflow_dispatch.main.default.slsa3.yml"><img alt=".github/workflows/e2e.nodejs.workflow_dispatch.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.nodejs.workflow_dispatch.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
  </tbody>
</table>

### BYOB generic permissions builder e2e tests

<table>
  <thead>
    <tr>
      <th>Event</th>
      <th>Name</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2">create</td>
      <td>default</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.create.main.default.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.create.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.create.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>with sha1</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.create.main.checkout.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.create.main.checkout.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.create.main.checkout.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td rowspan="2">push</td>
      <td>default branch</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.push.main.default.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.push.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.push.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>push to tag</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.tag.main.default.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.tag.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.tag.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td rowspan="2">release</td>
      <td>default</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.release.main.default.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.release.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.release.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>With sha1</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.release.main.checkout.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.release.main.checkout.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.release.main.checkout.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td rowspan="4">workflow_dispatch</td>
      <td>default branch</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.workflow_dispatch.main.default.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.workflow_dispatch.main.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.workflow_dispatch.main.default.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>default branch w/ sha1</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.workflow_dispatch.main.checkout.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.workflow_dispatch.main.checkout.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.workflow_dispatch.main.checkout.slsa3.yml/badge.svg" /></a></td>
    </tr>
    <tr>
      <td>non-default branch</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.workflow_dispatch.branch1.default.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.workflow_dispatch.branch1.default.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.workflow_dispatch.branch1.default.slsa3.yml/badge.svg?branch=branch1&event=workflow_dispatch" /></a></td>
    </tr>
    <tr>
      <td>non-default branch w/ sha1</td>
      <td><a href="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.workflow_dispatch.branch1.checkout.slsa3.yml"><img alt=".github/workflows/e2e.delegator-generic.workflow_dispatch.branch1.checkout.slsa3.yml" src="https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-generic.workflow_dispatch.branch1.checkout.slsa3.yml/badge.svg?branch=branch1&event=workflow_dispatch" /></a></td>
    </tr>
  </tbody>
</table>

### BYOB low permissions builder e2e tests

| Name              | Status                                                                                                                                                                                                                                                                                                                                                                                             |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| workflow_dispatch | [![.github/workflows/e2e.delegator-lowperms.workflow_dispatch.main.default.slsa3.yml](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.workflow_dispatch.main.default.slsa3.yml/badge.svg?event=workflow_dispatch)](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.workflow_dispatch.main.default.slsa3.yml) |
| release           | [![.github/workflows/e2e.delegator-lowperms.release.main.default.slsa3.yml](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.release.main.default.slsa3.yml/badge.svg)](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.release.main.default.slsa3.yml)                                                       |
| create            | [![.github/workflows/e2e.delegator-lowperms.create.main.default.slsa3.yml](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.create.main.default.slsa3.yml/badge.svg)](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.create.main.default.slsa3.yml)                                                          |
| push              | [![.github/workflows/e2e.delegator-lowperms.push.main.default.slsa3.yml](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.push.main.default.slsa3.yml/badge.svg?event=push)](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.push.main.default.slsa3.yml)                                                     |
| tag               | [![.github/workflows/e2e.delegator-lowperms.tag.main.default.slsa3.yml](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.tag.main.default.slsa3.yml/badge.svg?event=push)](https://github.com/slsa-framework/example-package/actions/workflows/e2e.delegator-lowperms.tag.main.default.slsa3.yml)                                                        |
