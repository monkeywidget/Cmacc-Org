#!/usr/bin/env bash
# Render every Mermaid block in the given Markdown files with a pinned
# mermaid-cli image; report ok/FAIL per block and keep PNGs for inspection.
# Usage: check-diagrams.sh [file.md ...]   (default: tracked docs with diagrams)
# PNGs go to $CMACC_DIAGRAM_OUT (default $TMPDIR/cmacc-diagrams).
set -u

cd "$(dirname "$0")/../.."
CONTEXT=${CMACC_CONTEXT:-orbstack}
IMAGE=minlag/mermaid-cli:11.4.2@sha256:99c983b3ab4e14033f2880bc1b9de17e5090b4515dabd63fe9cf8c0ae6130956
TMP=${TMPDIR:-/tmp}
OUT=${CMACC_DIAGRAM_OUT:-${TMP%/}/cmacc-diagrams}

if [ $# -eq 0 ]; then
  set -- $(git ls-files '*.md' ':!:Doc/**' | xargs grep -l '^```mermaid' 2>/dev/null)
fi
rm -rf "$OUT" && mkdir -p "$OUT" && chmod 777 "$OUT"

# Split each file's mermaid blocks into <name>-<n>.mmd.
for f in "$@"; do
  awk -v out="$OUT" -v name="$(echo "$f" | tr '/.' '__')" '
    /^```mermaid/ { n++; file = sprintf("%s/%s-%d.mmd", out, name, n); inblock = 1; next }
    /^```/ && inblock { inblock = 0; close(file); next }
    inblock { print > file }' "$f"
done

failed=0
for m in "$OUT"/*.mmd; do
  [ -e "$m" ] || { echo "No mermaid blocks found."; exit 0; }
  b=$(basename "$m" .mmd)
  if docker --context "$CONTEXT" run --rm --network none -v "$OUT:/data" "$IMAGE" \
      -i "/data/$b.mmd" -o "/data/$b.png" -q -w 1400 >/dev/null 2>"$OUT/$b.err"; then
    echo "  ok    $b"
  else
    echo "  FAIL  $b: $(grep -m1 -E 'Error|error' "$OUT/$b.err")"
    failed=$((failed + 1))
  fi
done
echo "PNGs: $OUT"
[ "$failed" -eq 0 ]
