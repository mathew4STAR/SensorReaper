#!/usr/bin/env bash
# Render existing LLVM IR; compilation belongs to run_pipeline.sh.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  printf 'Usage: bash scripts/visualize_cfg.sh PIPELINE_OUTPUT_DIRECTORY\n' >&2
  exit 1
fi
input="$(realpath "$1")"
opt_tool="${OPT:-opt-18}"
for tool in "$opt_tool" dot; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing %s. Install: sudo apt install llvm-18 graphviz\n' "$tool" >&2
    exit 1
  fi
done
for stage in before after; do
  if [[ ! -f "$input/$stage.ll" ]]; then
    printf 'Missing %s/%s.ll; run run_pipeline.sh first.\n' "$input" "$stage" >&2
    exit 1
  fi
done

# Isolate each rendering so old DOT files cannot become stale comparison graphs.
output="$(mktemp -d "$input/cfg.XXXXXX")"
for stage in before after; do
  mkdir "$output/$stage"
  # LLVM exports blocks and edges directly from the supplied IR.
  "$opt_tool" -passes='dot-cfg' -disable-output "$input/$stage.ll" \
    -cfg-dot-filename-prefix="$output/$stage/cfg" \
    2> "$output/$stage/graph-generation.log"
  # nullglob safely handles modules without any defined functions.
  shopt -s nullglob
  for graph in "$output/$stage/"*.dot; do
    dot -Tsvg "$graph" -o "${graph%.dot}.svg"
  done
done
printf 'CFG output: %s\n' "$output"
