#!/usr/bin/env bash

set -euo pipefail

if ! command -v go >/dev/null 2>&1; then
  echo "Error: go is not installed or not in PATH."
  exit 1
fi

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
    echo "Error: invalid GOLANGCI_LINT_VERSION='${version}'. Use 'latest' or 'v2.X.Y'."
    exit 1
  fi

  target_major="$(printf '%s\n' "${version}" | sed -nE 's/^v([0-9]+)\..*/\1/p')"
  if [[ "${target_major}" != "2" ]]; then
    echo "Error: GOLANGCI_LINT_VERSION must target golangci-lint v2 (got '${version}')."
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
    echo "Error: golangci-lint was not found in ${gobin} after installation."
    exit 1
  fi

  if command -v golangci-lint >/dev/null 2>&1; then
    echo "golangci-lint installed: $(installed_version_line)"
    return 0
  fi

  echo "golangci-lint installed at ${gobin}/golangci-lint"
  echo "Add this to your shell profile:"
  echo "  export PATH=\"${gobin}:\$PATH\""
}

install_golangci_lint() {
  local version="${GOLANGCI_LINT_VERSION:-v2.11.3}"
  local module="github.com/golangci/golangci-lint/v2/cmd/golangci-lint"
  local version_line=""
  local current_major=""
  local current_version=""

  version="$(normalize_version "${version}")"
  validate_version "${version}"

  if command -v golangci-lint >/dev/null 2>&1; then
    version_line="$(installed_version_line)"
    current_major="$(installed_major "${version_line}")"
    current_version="$(installed_version "${version_line}")"

    if [[ "${current_major}" =~ ^[0-9]+$ ]] && ((current_major >= 2)); then
      if [[ "${version}" == "latest" ]]; then
        echo "golangci-lint v2 detected (${current_version}), reinstalling latest..."
      elif [[ "${current_version}" == "${version}" ]]; then
        echo "golangci-lint is already installed: ${version_line}"
        return 0
      else
        echo "golangci-lint v2 detected (${current_version}), switching to ${version}..."
      fi
    elif [[ "${current_major}" == "1" ]]; then
      echo "golangci-lint v1 detected, upgrading to ${version}..."
    else
      echo "Unable to determine golangci-lint major version from: ${version_line}"
      echo "Reinstalling golangci-lint (${version})..."
    fi
  else
    echo "Installing golangci-lint (${version})..."
  fi

  go install "${module}@${version}"
  verify_installation
}

install_golangci_lint
