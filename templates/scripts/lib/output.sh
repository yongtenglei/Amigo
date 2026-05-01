#!/bin/sh

script_section() {
  printf '\n== %s ==\n' "$1"
}

script_step() {
  printf '%s\n' "$1"
}

script_ok() {
  printf 'OK: %s\n' "$1"
}

script_warn() {
  printf 'WARN: %s\n' "$1"
}

script_error() {
  printf 'ERROR: %s\n' "$1" >&2
}

script_detail() {
  printf '  - %s\n' "$1"
}
