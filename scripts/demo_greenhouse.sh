#!/usr/bin/env bash
# Run one demonstration; --no-open is useful on a terminal without a desktop.
set -euo pipefail
if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--no-open" ) ]]; then
  printf 'Usage: bash scripts/demo_greenhouse.sh [--no-open]\n' >&2
  exit 1
fi
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

# Rebuild incrementally so the demonstration uses the current pass source.
export BUILD_DIR="${BUILD_DIR:-$project_root/build}"
export SENSOR_PLUGIN="${SENSOR_PLUGIN:-$BUILD_DIR/SensorReaperPass.so}"
bash scripts/build.sh
output="$(bash scripts/run_pipeline.sh tests/c/looping_greenhouse_supervisor.c)"

# Reuse measurement helpers without executing evaluate.py's full-suite main().
python3 - "$project_root" "$output" <<'PY'
import os
from pathlib import Path
import re
import runpy
import shutil
import sys

root, output = map(Path, sys.argv[1:])
helpers = runpy.run_path(str(root / "scripts/evaluate.py"))
clang = os.environ.get("CLANG", "clang-18")
size_tool = shutil.which("llvm-size-18") or shutil.which("size")
metrics = []
for stage in ("before", "after"):
    ir, obj = output / f"{stage}.ll", output / f"{stage}.o"
    # Match the evaluator's backend settings and measure the actual host object.
    helpers["run"](clang, "-O0", "-c", str(ir), "-o", str(obj))
    metrics.append(dict(helpers["ir_metrics"](ir),
                        text_bytes=helpers["text_size"](size_tool, obj)))

print("\nGreenhouse results (host objects; .text is machine-code bytes)")
print(f"{'Metric':<24} {'Baseline':>10} {'Ours':>10} {'Saved':>10} {'Saved %':>10}")
for metric in metrics[0]:
    before, after = metrics[0][metric], metrics[1][metric]
    saved = None if before is None or after is None else before - after
    percent = None if saved is None or before == 0 else f"{100 * saved / before:.2f}%"
    values = [helpers["show"](v) for v in (before, after, saved, percent)]
    print(f"{metric:<24} " + " ".join(f"{value:>10}" for value in values))

# Print the real pass summary without creating a CSV or Markdown report.
proofs = (output / "proofs.txt").read_text()
summaries = re.findall(r"^.*summary for.*$", proofs, re.M)
if not summaries:
    raise RuntimeError("The pass produced no summary; inspect proofs.txt")
print("\n" + "\n".join(summaries))
print(f"Artifacts: {output}")
PY

# Delegate graph conversion to the visualizer; do not repeat its Graphviz logic.
message="$(bash scripts/visualize_cfg.sh "$output")"
printf '%s\n' "$message"
graphs="${message#CFG output: }"
if [[ "${1:-}" != "--no-open" ]]; then
  if ! command -v xdg-open >/dev/null 2>&1; then
    printf 'Auto-open unavailable. Install xdg-utils or open the SVGs manually.\n' >&2
    exit 1
  fi
  for stage in before after; do
    image="$graphs/$stage/cfg.run_greenhouse_supervisor.svg"
    # The desktop chooses its default SVG viewer; log viewer errors per image.
    printf 'Opening %s\n' "$image"
    xdg-open "$image" > "$graphs/$stage/viewer.log" 2>&1 &
  done
fi
