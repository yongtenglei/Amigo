<p align="center">
  <img src=".github/assets/amigo-logo.png" alt="Amigo logo" width="420">
  <br>
  <img src="https://img.shields.io/badge/made%20by-my%20sister-e75480?style=for-the-badge" alt="made by my sister">
</p>

# amigo

Shared GitHub Actions workflows, lint configuration, and reusable tooling assets for Go repositories.

## Contents

- `golangci.yml`: shared golangci-lint rules
- `templates/.markdownlint.jsonc`: shared markdownlint config
- `templates/.prettierrc.json`: shared Prettier config
- `templates/scripts/install_deps.sh`: shared tooling installer script
- `templates/scripts/lib/output.sh`: shared shell output helpers
- `.github/workflows/lint.yml`: reusable lint workflow
- `.github/workflows/build.yml`: reusable build and test workflow
- `.github/workflows/docs-format.yml`: reusable workflow to format Markdown and open a pull request when changes are
  needed
- `.github/workflows/lint-sync.yml`: reusable workflow to open a PR syncing `golangci.yml` into a target repository
- `.github/workflows/tooling-sync.yml`: reusable workflow to open a PR syncing shared tooling assets into a target
  repository
- `.github/workflows/dependabot-sync.yml`: reusable workflow to sync shared Dependabot configuration into a target
  repository

## Usage

PR-producing workflows use `GITHUB_TOKEN` by default and require **Allow GitHub Actions to create and approve pull
requests**. To trigger downstream workflows, pass `amigo_pull_request_token` with read and write access to contents and
pull requests.

### `lint.yml`

This workflow runs `golangci-lint` on Linux, macOS, and Windows by default. It checks out both the target repository and
`amigo`, then runs `golangci-lint` with either:

- the target repository's own config via `golangci_path`
- `amigo/golangci.yml` if `golangci_path` is not set

Set `os` to a JSON array of runner labels to select the lint matrix.

Use this when a repository wants a shared lint job in CI.

```yaml
permissions:
  contents: read
  pull-requests: read

jobs:
  lint:
    uses: yongtenglei/amigo/.github/workflows/lint.yml@main
    with:
      go-version-file: ./go.mod
      golangci_path: .golangci.yml
      golangci_version: v2.11.3
      os: '["ubuntu-latest"]'
```

### `build.yml`

This workflow runs two jobs:

- `govulncheck` on Ubuntu
- `go build` and `go test` on Linux, macOS, and Windows by default

Set `os` to a JSON array of runner labels to select the build and test matrix. Before those checks, it runs
`go mod tidy` and fails if that produces working tree drift. Use this when a repository wants a shared Go validation
pipeline.

```yaml
jobs:
  build:
    uses: yongtenglei/amigo/.github/workflows/build.yml@main
    with:
      go-version-file: ./go.mod
      os: '["ubuntu-latest"]'
      test-command: go test ./...
```

### `docs-format.yml`

This workflow formats tracked Markdown files and opens a pull request when the formatter changes them.

It prefers `.markdownlint.jsonc` and `.prettierrc.json` from the target repository. If either file is missing, it falls
back to the shared config in `amigo/templates`.

Use this when a repository wants Markdown formatting managed through a shared workflow.

```yaml
permissions:
  contents: write
  pull-requests: write

jobs:
  docs:
    uses: yongtenglei/amigo/.github/workflows/docs-format.yml@main
    secrets:
      amigo_pull_request_token: ${{ secrets.AMIGO_PULL_REQUEST_TOKEN }}
```

### `lint-sync.yml`

This workflow does not run lint. It checks out the target repository and `amigo`, copies `amigo/golangci.yml` to
`.golangci.yml`, and opens a pull request with the change.

Use this when a repository wants to keep a checked-in `.golangci.yml` synced from `amigo`, usually together with
`lint.yml`.

```yaml
permissions:
  contents: write
  pull-requests: write

jobs:
  lint:
    uses: yongtenglei/amigo/.github/workflows/lint-sync.yml@main
    secrets:
      amigo_pull_request_token: ${{ secrets.AMIGO_PULL_REQUEST_TOKEN }}
```

### `tooling-sync.yml`

This workflow checks out the target repository and `amigo`, syncs shared tooling files from `amigo` into the target
repository, and opens a pull request with the change.

Use this when a repository wants to keep shared tooling files synced from `amigo`.

```yaml
permissions:
  contents: write
  pull-requests: write

jobs:
  tooling:
    uses: yongtenglei/amigo/.github/workflows/tooling-sync.yml@main
    secrets:
      amigo_pull_request_token: ${{ secrets.AMIGO_PULL_REQUEST_TOKEN }}
```

### `dependabot-sync.yml`

This workflow assembles the expected Dependabot configuration from `amigo/.github/dependabot.yml` (base), shared
additions such as `amigo/dependabot/dependabot-gomod.yml`, and an optional
`amigo/dependabot/dependabot-<repository>.yml` (repo-specific additions), then compares it with the target repository's
`.github/dependabot.yml` and opens a pull request when changes are needed.

Use this when a repository wants its Dependabot config managed through `amigo`.

```yaml
permissions:
  contents: write
  pull-requests: write

jobs:
  dependabot-sync:
    uses: yongtenglei/amigo/.github/workflows/dependabot-sync.yml@main
    secrets:
      amigo_pull_request_token: ${{ secrets.AMIGO_PULL_REQUEST_TOKEN }}
```

## License

Except for the Amigo logo, this repository is licensed under the [MIT License](LICENSE.txt). The Amigo logo is © 2026
liuzi. All rights reserved.
