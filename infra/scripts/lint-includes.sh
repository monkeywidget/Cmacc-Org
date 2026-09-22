#!/usr/bin/env bash
# Fail if an include target only resolves on a case-insensitive filesystem.
# Missing targets are reported, not fatal. Runs in the pinned Python image, so
# the host needs only Docker.
set -euo pipefail

cd "$(dirname "$0")/../.."
CONTEXT=${CMACC_CONTEXT:-orbstack}
IMAGE=$(sed -n 's/.*"image": "\([^"]*\)".*/\1/p' tests/renderer/runtime.json | head -n 1)

docker --context "$CONTEXT" run --rm --pull=never --network none \
  --mount "type=bind,src=$PWD,dst=/workspace,readonly" \
  --workdir /workspace --env PYTHONDONTWRITEBYTECODE=1 \
  "$IMAGE" python tools/check_includes.py "$@"
