#!/usr/bin/env python3
"""Run the shared pipeline and check existing fixtures at function granularity."""
import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


# Run a command without shell interpretation and stop on any tool failure.
def run(*command):
    return subprocess.run(command, cwd=ROOT, check=True, text=True,
                          capture_output=True).stdout


# Extract one function body so a passing function cannot hide a failing neighbor.
def body(ir, name):
    match = re.search(r"^define\b[^\n]*@" + re.escape(name)
                      + r"\([^\n]*\)[^\n]*\{\n(.*?)^}", ir, re.M | re.S)
    if not match:
        raise AssertionError(f"missing function: {name}")
    return match.group(1)


# Count actual call instructions rather than declarations or diagnostic strings.
def calls(ir, name):
    return len(re.findall(r"\bcall\b[^\n]*@" + re.escape(name) + r"\(", ir))


# Check baseline presence as well as optimized absence to prevent vacuous passes.
def check_dead(before, after, name, expected):
    before, after = body(before, name), body(after, name)
    assert calls(before, "err") == expected, f"{name}: baseline lacks expected errors"
    assert calls(after, "err") == 0, f"{name}: dead error call remains"


# Check each live fixture's alarm and conditional branch independently.
def check_live(before, after, name):
    for ir in (body(before, name), body(after, name)):
        assert calls(ir, "alarm") == 1, f"{name}: live alarm missing"
        assert re.search(r"\bbr i1\b", ir), f"{name}: live branch missing"


# Test transformations, conservative fallbacks, range diagnostics, and unit tests.
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="directory for this test run")
    args = parser.parse_args()
    plugin = Path(os.environ.get("SENSOR_PLUGIN", ROOT / "build/SensorReaperPass.so"))
    if not plugin.is_file():
        run("bash", str(ROOT / "scripts/build.sh"))
    if args.output:
        output = args.output.resolve()
        output.mkdir(parents=True, exist_ok=True)
    else:
        (ROOT / "results").mkdir(exist_ok=True)
        output = Path(tempfile.mkdtemp(prefix="checks.", dir=ROOT / "results"))

    # Every current fixture has an explicit expectation; new ones require a rule.
    dead = {"dead_low_bound": 1, "dead_high_bound": 1,
            "redundant_validation": 1, "arithmetic_chain": 1,
            "realistic_esp32_style": 6, "looping_greenhouse_supervisor": 22}
    names = {"realistic_esp32_style": "run_environment_controller",
             "looping_greenhouse_supervisor": "run_greenhouse_supervisor"}
    live = {"live_threshold": ["live_threshold"], "unknown_sensor": ["unknown_sensor"],
            "unknown_input_and_overflow": ["mixed_with_parameter", "possible_overflow"]}
    diagnostics = {
        "sensor_seed_demo": ["seeded temp_sensor as [-40, 85]"],
        "phi_merge": ["inferred [-40, 100] in select_environment_value"],
        "interval_propagation_demo": ["inferred [-180, 320] in transform_temperature",
                                      "inferred [-40, 85] in extend_temperature",
                                      "inferred [0, 100] in extend_humidity",
                                      "inferred [-40, 85] in narrow_temperature"]}
    fixtures = sorted((ROOT / "tests/c").glob("*.c"))
    expected = set(dead) | set(live) | set(diagnostics) | {"constant_folding"}
    assert {p.stem for p in fixtures} == expected, "fixture list and expectations differ"

    for source in fixtures:
        target = output / source.stem
        run("bash", str(ROOT / "scripts/run_pipeline.sh"), str(source), str(target))
        before = (target / "before.ll").read_text()
        after = (target / "after.ll").read_text()
        proofs = (target / "proofs.txt").read_text()
        if source.stem in dead:
            check_dead(before, after, names.get(source.stem, source.stem), dead[source.stem])
        for name in live.get(source.stem, []):
            check_live(before, after, name)
        for text in diagnostics.get(source.stem, []):
            assert text in proofs, f"{source.stem}: missing diagnostic {text}"
        if source.stem == "constant_folding":
            name = "folded_sensor_expression"
            assert "mul nsw i32" in body(before, name), "baseline multiplication missing"
            assert "mul " not in body(after, name), "constant multiplication remains"
            assert "ret i32 0" in body(after, name), "constant return missing"
            assert calls(body(after, name), "sensor_read") == 1, "sensor side effect removed"
        if source.stem in names:
            # Both sides of every real actuator decision must survive cleanup.
            controls = (["fan_on", "fan_off", "dehumidifier_on", "dehumidifier_off",
                         "vent_on", "vent_off", "brighten_lights", "dim_lights"]
                        if source.stem == "realistic_esp32_style" else
                        ["fan_on", "fan_off", "mist_on", "mist_off", "vents_open",
                         "vents_close", "grow_lights_on", "grow_lights_off"])
            for control in controls + ["alarm"]:
                assert calls(body(after, names[source.stem]), control) == 1, control
            if source.stem == "looping_greenhouse_supervisor":
                function = body(after, names[source.stem])
                assert "phi i32" in function and "icmp slt" in function, "loop missing"
                assert len(re.findall(r"\bbr i1\b", function)) >= 5, "live decisions missing"
        print(f"PASS {source.name}")

    # Compile both C++ unit tests independently of the plugin build.
    for name in ("interval_test", "spec_loader_test"):
        command = shlex.split(os.environ.get("CXX", "c++"))
        command += ["-std=c++17", "-I", str(ROOT / "src"), str(ROOT / f"tests/{name}.cpp")]
        if name == "spec_loader_test":
            command.append(str(ROOT / "src/SpecLoader.cpp"))
        executable = output / name
        run(*command, "-o", str(executable))
        print(run(str(executable)).strip())
        print(f"PASS {name}")
    print(f"All {len(fixtures)} C fixtures and 2 C++ unit tests passed.")
    print(f"Results: {output}")


# Report tool failures and failed expectations as a nonzero checker exit status.
if __name__ == "__main__":
    try:
        main()
    except (AssertionError, OSError, subprocess.CalledProcessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            print(error.stdout, error.stderr, file=sys.stderr)
        sys.exit(1)
