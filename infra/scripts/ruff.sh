#!/usr/bin/env bash
# Run Ruff on the Python app with the project's config (app/pyproject.toml).
# app/ is mounted read-write as your user, so `check --fix` and `format` edit files in place.
# Usage: ruff.sh [ruff args...]   default: check
#   ruff.sh check              # findings
#   ruff.sh check --fix        # apply safe fixes
#   ruff.sh format [--check]   # reformat (or just report)
set -euo pipefail

cd "$(dirname "$0")/../.."
CONTEXT=${CMACC_CONTEXT:-orbstack}
docker --context "$CONTEXT" image inspect cmacc-app:test >/dev/null 2>&1 || infra/scripts/app-image.sh test

docker --context "$CONTEXT" run --rm --pull=never --network none \
  --user "$(id -u):$(id -g)" --env HOME=/tmp --env RUFF_NO_CACHE=true \
  --mount "type=bind,src=$PWD/app,dst=/work" --workdir /work \
  cmacc-app:test ruff "${@:-check}"
