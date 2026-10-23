#!/usr/bin/env python3
"""Measure baseline and optimized IR/objects using the existing pipeline."""
import csv
from datetime import datetime, timezone
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


# Run tools without shell interpretation and capture failures for diagnostics.
def run(*command):
    return subprocess.run(command, cwd=ROOT, check=True, text=True,
                          capture_output=True).stdout


# Count scalar IR instructions and blocks inside function definitions only.
def ir_metrics(path):
    branches = instructions = blocks = 0
    inside = first = multiline = False
    for line in path.read_text().splitlines():
        text = line.strip()
        if text.startswith("define "):
            inside, first = True, True
        elif inside and text == "}":
            inside = False
        elif inside and text and not text.startswith(";"):
            if re.match(r'^(?:[-\w.$]+|"[^"]+"):', text):
                blocks += 1
                first = False
            else:
                # Count the implicit entry block when LLVM omits its label.
                if first:
                    blocks += 1
                    first = False
                branches += bool(re.match(r"br\s+i1\b", text))
                instructions += 1
                # Avoid presenting line counts as instruction counts for multiline IR.
                multiline |= bool(re.search(r"\b(switch|invoke|callbr|landingpad|catchswitch)\b", text))
    return {"conditional_branches": branches,
            "instructions": None if multiline else instructions, "basic_blocks": blocks}


# Measure .text sections rather than total file size, symbols, data, or unwind info.
def text_size(tool, path):
    if not tool:
        return None
    try:
        sizes = re.findall(r"^\.text(?:\.\S+)?\s+(\d+)\s+",
                           run(tool, "-A", str(path)), re.M)
        return sum(map(int, sizes)) if sizes else None
    except (OSError, subprocess.CalledProcessError):
        return None


# Represent missing measurements and zero-baseline percentages explicitly.
def show(value):
    return "n/a" if value is None else str(value)


# Rebuild and evaluate each fixture, preserving its IR, proof log, and object files.
def main():
    build = Path(os.environ.get("BUILD_DIR", ROOT / "build")).resolve()
    plugin = Path(os.environ.get("SENSOR_PLUGIN", build / "SensorReaperPass.so")).resolve()
    os.environ["SENSOR_PLUGIN"] = str(plugin)
    run("bash", str(ROOT / "scripts/build.sh"))
    if not plugin.is_file():
        raise RuntimeError(f"Plugin missing after build: {plugin}")
    clang = os.environ.get("CLANG", "clang-18")
    opt = os.environ.get("OPT", "opt-18")
    size = shutil.which("llvm-size-18") or shutil.which("size")
    results = ROOT / "results"
    results.mkdir(exist_ok=True)
    artifacts = Path(tempfile.mkdtemp(prefix="evaluation.", dir=results))
    rows = []
    for source in sorted((ROOT / "tests/c").glob("*.c")):
        target = artifacts / source.stem
        run("bash", str(ROOT / "scripts/run_pipeline.sh"), str(source), str(target))
        metrics = []
        for stage in ("before", "after"):
            ir, obj = target / f"{stage}.ll", target / f"{stage}.o"
            # Use identical backend settings for both host object files.
            run(clang, "-O0", "-c", str(ir), "-o", str(obj))
            metrics.append(dict(ir_metrics(ir), text_bytes=text_size(size, obj)))
        summaries = re.findall(r"comparisons proven true=(\d+), comparisons proven false=(\d+)",
                               (target / "proofs.txt").read_text())
        if not summaries:
            raise RuntimeError(f"Missing pass summary: {source.name}")
        proven_true = sum(int(t) for t, f in summaries)
        proven_false = sum(int(f) for t, f in summaries)
        for metric in metrics[0]:
            before, after = metrics[0][metric], metrics[1][metric]
            reduction = None if before is None or after is None else before - after
            percent = None if reduction is None or before == 0 else f"{100 * reduction / before:.2f}"
            rows.append([source.stem, metric, show(before), show(after), show(reduction),
                         show(percent), proven_true, proven_false])
        print(f"Measured {source.name}: true={proven_true}, false={proven_false}")

    header = ["test", "metric", "baseline", "ours", "reduction", "reduction_percent",
              "proven_true", "proven_false"]
    with (results / "results.csv").open("w", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(header)
        writer.writerows(rows)
    # Keep the counting contract and measurement environment alongside the numbers.
    notes = ["# SensorReaper measured results", "",
             f"Generated (UTC): {datetime.now(timezone.utc).isoformat()}",
             f"Clang: {run(clang, '--version').splitlines()[0]}",
             f"opt: {run(opt, '--version').splitlines()[0]}",
             f"Target: {run(clang, '-dumpmachine').strip()}", f"Size tool: {size or 'n/a'}",
             f"Artifacts: {artifacts.name}/", "",
             "Pipelines: mem2reg,simplifycfg,dce versus mem2reg,sensor-range-elim,simplifycfg,dce.",
             "C input: -O0 -Xclang -disable-O0-optnone. Objects: clang -O0 -c on each IR.",
             "Branches: br i1 instructions. Blocks: explicit labels plus implicit entries.",
             "Instructions: nonempty, noncomment, nonlabel lines inside function bodies;",
             "current scalar fixtures use one line per instruction. Multiline IR yields n/a.",
             "Text bytes: sum of .text and .text.* sections from size -A on unlinked objects.",
             "Reduction = baseline minus ours; negative means growth. Zero-baseline % is n/a.",
             "Proof totals are summed across functions, repeated per metric (do not sum rows).",
             "Host code-size/IR measurements are not ESP32 execution-time or energy results.", "",
             "| " + " | ".join(header) + " |", "| " + " | ".join(["---"] * len(header)) + " |"]
    notes += ["| " + " | ".join(map(str, row)) + " |" for row in rows]
    (results / "results.md").write_text("\n".join(notes) + "\n")
    print(f"Wrote {results / 'results.csv'} and {results / 'results.md'}")


# Compilation failures stop evaluation; only unavailable measurements become n/a.
if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Evaluation failed: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            print(error.stdout, error.stderr, file=sys.stderr)
        sys.exit(1)
