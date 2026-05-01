#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=scripts/lib/output.sh
. "$ROOT_DIR/scripts/lib/output.sh"

script_section "Go toolchain"
if ! command -v go >/dev/null 2>&1; then
  script_error "go is not installed or not in PATH."
  exit 1
fi
script_ok "go is available"

normalize_version() {
  local version="$1"

  if [[ "${version}" != "latest" && "${version}" != v* ]]; then
    version="v${version}"
  fi

  printf '%s\n' "${version}"
}

validate_version() {
  local version="$1"
  local target_major=""

  if [[ "${version}" == "latest" ]]; then
    return 0
  fi

  if [[ ! "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    script_error "invalid GOLANGCI_LINT_VERSION='${version}'. Use 'latest' or 'v2.X.Y'."
    exit 1
  fi

  target_major="$(printf '%s\n' "${version}" | sed -nE 's/^v([0-9]+)\..*/\1/p')"
  if [[ "${target_major}" != "2" ]]; then
    script_error "GOLANGCI_LINT_VERSION must target golangci-lint v2 (got '${version}')."
    exit 1
  fi
}

installed_version_line() {
  golangci-lint version | head -n 1
}

installed_version() {
  printf '%s\n' "$1" | sed -nE 's/.*version v?([0-9]+\.[0-9]+\.[0-9]+).*/v\1/p'
}

installed_major() {
  printf '%s\n' "$1" | sed -nE 's/.*version v?([0-9]+).*/\1/p'
}

resolve_gobin() {
  local gobin=""

  gobin="$(go env GOBIN)"
  if [[ -z "${gobin}" ]]; then
    gobin="$(go env GOPATH)/bin"
  fi

  printf '%s\n' "${gobin}"
}

verify_installation() {
  local gobin=""

  gobin="$(resolve_gobin)"
  if [[ ! -x "${gobin}/golangci-lint" ]]; then
    script_error "golangci-lint was not found in ${gobin} after installation."
    exit 1
  fi

  if command -v golangci-lint >/dev/null 2>&1; then
    script_ok "golangci-lint installed: $(installed_version_line)"
    return 0
  fi

  script_ok "golangci-lint installed at ${gobin}/golangci-lint"
  script_warn "golangci-lint is not on PATH"
  script_detail "Add this to your shell profile: export PATH=\"${gobin}:\$PATH\""
}

install_golangci_lint() {
  local version="${GOLANGCI_LINT_VERSION:-v2.11.3}"
  local module="github.com/golangci/golangci-lint/v2/cmd/golangci-lint"
  local version_line=""
  local current_major=""
  local current_version=""

  script_section "golangci-lint"
  version="$(normalize_version "${version}")"
  script_detail "Requested version: ${version}"
  validate_version "${version}"

  if command -v golangci-lint >/dev/null 2>&1; then
    version_line="$(installed_version_line)"
    current_major="$(installed_major "${version_line}")"
    current_version="$(installed_version "${version_line}")"
    script_detail "Detected version: ${version_line}"

    if [[ "${current_major}" =~ ^[0-9]+$ ]] && ((current_major >= 2)); then
      if [[ "${version}" == "latest" ]]; then
        script_step "Reinstalling latest golangci-lint v2..."
      elif [[ "${current_version}" == "${version}" ]]; then
        script_ok "golangci-lint is already installed"
        return 0
      else
        script_step "Switching golangci-lint from ${current_version} to ${version}..."
      fi
    elif [[ "${current_major}" == "1" ]]; then
      script_step "Upgrading golangci-lint v1 to ${version}..."
    else
      script_warn "Unable to determine golangci-lint major version"
      script_detail "${version_line}"
      script_step "Reinstalling golangci-lint (${version})..."
    fi
  else
    script_step "Installing golangci-lint (${version})..."
  fi

  go install "${module}@${version}"
  verify_installation
}

install_golangci_lint
