#!/usr/bin/env bash
# Stop on configuration or compilation failure.
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
llvm_config="${LLVM_CONFIG:-llvm-config-18}"

# Print actionable installation instructions when the development tools are absent.
for tool in cmake "$llvm_config"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing %s. Install: sudo apt install llvm-18-dev clang-18 llvm-18-tools cmake\n' "$tool" >&2
    exit 1
  fi
done

# Reject LLVM releases older than the opaque-pointer versions supported here.
llvm_version="$("$llvm_config" --version)"
if [[ "${llvm_version%%.*}" -lt 15 ]]; then
  printf 'LLVM 15 or newer is required; found %s\n' "$llvm_version" >&2
  exit 1
fi

# Reuse CMake's incremental build; do not delete caches or change cached compilers.
build_dir="${BUILD_DIR:-$project_root/build}"
cmake -S "$project_root" -B "$build_dir" \
  -DLLVM_DIR="$("$llvm_config" --cmakedir)" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build "$build_dir"
printf 'Plugin: %s/SensorReaperPass.so\n' "$build_dir"
