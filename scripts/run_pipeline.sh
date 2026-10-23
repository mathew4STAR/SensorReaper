#!/usr/bin/env bash
# Fail immediately when a compiler command fails or a variable is unset.
set -euo pipefail

# Share compilation between the checker, visualizer, and future master runner.
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_file="$(realpath "${1:-$project_root/tests/c/dead_low_bound.c}")"
plugin="$(realpath "${SENSOR_PLUGIN:-$project_root/build/SensorReaperPass.so}")"
clang_tool="${CLANG:-clang-18}"
opt_tool="${OPT:-opt-18}"
for tool in "$clang_tool" "$opt_tool"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing %s. Install: sudo apt install clang-18 llvm-18\n' "$tool" >&2
    exit 1
  fi
done
if [[ ! -f "$source_file" || ! -f "$plugin" ]]; then
  printf 'Source or plugin missing; build SensorReaperPass.so first.\n' >&2
  exit 1
fi

# Explicit output directories are reusable; default runs preserve earlier outputs.
if [[ $# -ge 2 ]]; then
  mkdir -p "$2"
  output="$(realpath "$2")"
else
  mkdir -p "$project_root/results/pipelines"
  test_name="$(basename "$source_file" .c)"
  output="$(mktemp -d "$project_root/results/pipelines/$test_name.XXXXXX")"
fi

# Resolve the default sensor spec relative to the project root.
cd "$project_root"
"$clang_tool" -Xclang -ast-dump -fsyntax-only "$source_file" > "$output/ast.txt"
"$clang_tool" -S -emit-llvm -O0 -Xclang -disable-O0-optnone \
  "$source_file" -o "$output/input.ll"

# Use identical cleanup pipelines, with only our pass added to the second.
"$opt_tool" -passes='mem2reg,simplifycfg,dce' \
  "$output/input.ll" -S -o "$output/before.ll"
"$opt_tool" -load-pass-plugin="$plugin" \
  -passes='mem2reg,sensor-range-elim,simplifycfg,dce' \
  -sensor-range-verbose "$output/input.ll" -S -o "$output/after.ll" \
  2> "$output/proofs.txt"

# Print only the output path so other scripts can capture and reuse it.
printf '%s\n' "$output"
