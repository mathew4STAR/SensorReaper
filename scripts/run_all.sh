#!/usr/bin/env bash
# Compose the component scripts; never duplicate compilation or optimization here.
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--graphs" ) ]]; then
  printf 'Usage: bash scripts/run_all.sh [--graphs]\n' >&2
  exit 1
fi

# Keep environment overrides consistent between the builder and pipeline.
export BUILD_DIR="${BUILD_DIR:-$project_root/build}"
export SENSOR_PLUGIN="${SENSOR_PLUGIN:-$BUILD_DIR/SensorReaperPass.so}"
bash "$project_root/scripts/build.sh"
mkdir -p "$project_root/results"
output="$(mktemp -d "$project_root/results/run.XXXXXX")"

# The checker invokes run_pipeline.sh exactly once for each fixture.
python3 "$project_root/scripts/check_tests.py" --output "$output"
if [[ "${1:-}" == "--graphs" ]]; then
  for fixture in "$output"/*; do
    if [[ -d "$fixture" && -f "$fixture/before.ll" ]]; then
      bash "$project_root/scripts/visualize_cfg.sh" "$fixture"
    fi
  done
fi
printf 'Completed. Results: %s\n' "$output"
