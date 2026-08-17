#!/usr/bin/env bash
set -euo pipefail

# Reproducible same-machine A/B harness for the upstream and Rust-only trees.
# Usage:
#   ./scripts/benchmark-ab.sh /path/to/gigatoken /path/to/owt_train.txt 100
#
# The script deliberately uses the same current shell, Rust toolchain, CPU,
# input file, tokenizer override, and ENCODE_MB value for both trees. It does
# not claim that runs on different machines are comparable.

UPSTREAM=${1:?upstream repository path required}
DATASET=${2:?OWT dataset path required}
MB=${3:-100}
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/target/benchmark-ab"
mkdir -p "$OUT_DIR"
[[ -d "$UPSTREAM" ]] || { echo "ERROR: upstream repository not found: $UPSTREAM" >&2; exit 1; }
[[ -f "$DATASET" ]] || { echo "ERROR: dataset not found: $DATASET" >&2; exit 1; }
TMP_HOME="$(mktemp -d "${OUT_DIR}/home.XXXXXX")"
trap 'rm -rf "$TMP_HOME"' EXIT
mkdir -p "$TMP_HOME/data"
ln -s "$(cd "$(dirname "$DATASET")" && pwd)/$(basename "$DATASET")" "$TMP_HOME/data/owt_train.txt"
command -v cargo >/dev/null || { echo "ERROR: cargo is required" >&2; exit 1; }
command -v rustc >/dev/null || { echo "ERROR: rustc is required" >&2; exit 1; }

if command -v sha256sum >/dev/null; then
  sha256sum "$DATASET" | tee "$OUT_DIR/dataset.sha256"
elif command -v shasum >/dev/null; then
  shasum -a 256 "$DATASET" | tee "$OUT_DIR/dataset.sha256"
fi

printf 'rust: '; rustc --version
printf 'cargo: '; cargo --version
printf 'host: '; rustc -vV | sed -n 's/^host: //p'

run_one() {
  local name=$1
  local repo=$2
  local log="$OUT_DIR/${name}.log"
  echo "==> ${name}: ${repo}"
  (
    cd "$repo"
    HOME="$TMP_HOME" \
    XDG_CACHE_HOME="$OUT_DIR/cache" \
    ENCODE_MB="$MB" \
    cargo bench --bench encode_st -- --noplot
  ) 2>&1 | tee "$log"
}

run_one upstream "$UPSTREAM"
run_one rs-gigatoken "$ROOT"

echo "==> A/B logs written to $OUT_DIR"
