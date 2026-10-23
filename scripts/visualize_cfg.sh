#!/usr/bin/env bash
# Stop if compilation, optimization, or rendering fails.
set -euo pipefail

# Resolve project files independently of the caller's working directory.
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
source_file="${1:-tests/c/dead_low_bound.c}"
plugin="${SENSOR_PLUGIN:-$project_root/build/SensorReaperPass.so}"

# Require Graphviz as well as the matching LLVM tools used by this project.
for tool in clang-18 opt-18 dot; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing %s. Install dependencies: sudo apt install clang-18 llvm-18 graphviz\n' "$tool" >&2
    exit 1
  fi
done
if [[ ! -f "$source_file" || ! -f "$plugin" ]]; then
  printf 'Source or plugin missing. Supply a C source and build SensorReaperPass.so first.\n' >&2
  exit 1
fi

# Keep each run in its own directory so previous demonstration files are preserved.
test_name="$(basename "$source_file" .c)"
mkdir -p results/visualizations
output="$(mktemp -d "$project_root/results/visualizations/$test_name.XXXXXX")"

# Save Clang's syntax tree to explain the frontend stage before LLVM optimization.
clang-18 -Xclang -ast-dump -fsyntax-only "$source_file" > "$output/ast.txt"

# Disable optnone so LLVM cleanup passes can run on the unoptimized input.
clang-18 -S -emit-llvm -O0 -Xclang -disable-O0-optnone \
  "$source_file" -o "$output/input.ll"

# Both pipelines perform identical cleanup; only the optimized one uses our pass.
opt-18 -passes='mem2reg,simplifycfg,dce' \
  "$output/input.ll" -S -o "$output/before.ll"
opt-18 -load-pass-plugin="$plugin" \
  -passes='mem2reg,sensor-range-elim,simplifycfg,dce' \
  -sensor-range-verbose "$output/input.ll" -S -o "$output/after.ll" \
  2> "$output/proofs.txt"

# LLVM emits a DOT graph per defined function; Graphviz renders each graph as SVG.
for stage in before after; do
  mkdir "$output/$stage"
  opt-18 -passes='dot-cfg' -disable-output "$output/$stage.ll" \
    -cfg-dot-filename-prefix="$output/$stage/cfg" \
    2> "$output/$stage/graph-generation.log"
  for graph in "$output/$stage/"*.dot; do
    dot -Tsvg "$graph" -o "${graph%.dot}.svg"
  done
done

# Print generated paths and actual pass summaries for the demonstration.
printf 'Output directory: %s\n' "$output"
printf 'Before CFGs: %s/before/*.svg\nAfter CFGs: %s/after/*.svg\n' "$output" "$output"
printf 'Syntax tree: %s/ast.txt\nProof log: %s/proofs.txt\n' "$output" "$output"
grep 'summary for' "$output/proofs.txt" || true
