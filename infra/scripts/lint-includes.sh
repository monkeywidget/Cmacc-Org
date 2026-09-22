#!/usr/bin/env bash
# Fail if an include target only resolves on a case-insensitive filesystem.
# Missing targets are reported, not fatal. Runs in the pinned Python image, so
# the host needs only Docker.
set -euo pipefail

exec "$(dirname "$0")/pyrun.sh" tools/check_includes.py "$@"
