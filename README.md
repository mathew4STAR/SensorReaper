# SensorReaper

SensorReaper is a compiler-design microproject: an out-of-tree LLVM optimization
plugin that uses declared sensor limits to simplify integer computations and
remove impossible conditional paths in C programs.

It is an independent, scaled-down implementation inspired by CoSense (CC 2024).
It does not reproduce CoSense's implementation, benchmark results, or hardware
measurements.

## What it demonstrates

A normal compiler sees an unknown integer returned by a sensor function:

```c
int temperature = sensor_read("temp_sensor");
if (temperature < -100)
  err();
```

If the specification guarantees that this call returns values in [-40, 85],
the condition is always false. SensorReaper replaces the comparison's uses with
false; LLVM's subsequent simplifycfg and dce passes remove the unreachable path.

The pass also substitutes constants when a supported computation has a singleton
interval, such as humidity * 0 producing [0, 0]. Calls to sensor_read remain
because they may have side effects.

## Requirements and installation

Tested with Ubuntu 22.04, LLVM/Clang 18.1.8, CMake 3.22.1, and Python 3.
The pass uses C++17 and the LLVM new pass manager. Python scripts use only the
standard library. Graph generation requires Graphviz; desktop image opening
requires xdg-utils.

Once an LLVM 18 package repository is configured:

```bash
sudo apt update
sudo apt install llvm-18-dev clang-18 llvm-18-tools cmake g++ python3 graphviz xdg-utils
```

Ubuntu 22.04's default repositories may not provide LLVM 18. If apt cannot find
these packages, follow the repository setup instructions at
[apt.llvm.org](https://apt.llvm.org/) before installing them.

Verify the versioned tools:

```bash
clang-18 --version
opt-18 --version
llvm-config-18 --cmakedir
dot -V
```

LLVM 15+ is the intended API baseline; releases other than 18 have not been
verified. Use matching Clang, opt, and LLVM development libraries.

## Quick start

Run these commands from this repository's root:

```bash
bash scripts/build.sh
bash scripts/demo_greenhouse.sh
```

The demo builds incrementally, runs only the greenhouse fixture, prints its
measurements, generates before/after CFG SVGs, and requests that the desktop
open both images using xdg-open. The default viewer may be a browser.

To generate the same outputs without opening a viewer:

```bash
bash scripts/demo_greenhouse.sh --no-open
```

Run the current assertion suite and optional graphs:

```bash
bash scripts/run_all.sh
bash scripts/run_all.sh --graphs
```

Run measured evaluation separately:

```bash
python3 scripts/evaluate.py
```

The master runner currently builds and checks tests, with optional graphs.
Evaluation is a separate command; it is not automatically part of run_all.sh.

## Repository layout

```text
CMakeLists.txt                       LLVM discovery and plugin build
spec/sensors.json                    Named sensor bounds
src/SpecLoader.h, src/SpecLoader.cpp  Restricted specification loader
src/Interval.h                       Header-only integer interval operations
src/SensorRangePass.cpp              Analysis, transformations, registration
tests/c/                            C fixtures
tests/interval_test.cpp              Standalone interval assertions
tests/spec_loader_test.cpp           Standalone loader demonstration
scripts/build.sh                    Configure and build
scripts/run_pipeline.sh             C to baseline/optimized LLVM IR
scripts/check_tests.py              Per-function expectations and unit tests
scripts/run_all.sh                  Build, checks, optional CFG rendering
scripts/evaluate.py                 Full-suite measurement and reports
scripts/visualize_cfg.sh             Existing IR to DOT and SVG graphs
scripts/demo_greenhouse.sh           Single-fixture terminal/visual demo
results/                            Generated artifacts and reports
```

## Sensor specification and C interface

The current specification is:

```json
{
  "temp_sensor":     { "min": -40, "max": 85 },
  "humidity_sensor": { "min": 0,   "max": 100 },
  "pressure_sensor": { "min": 300, "max": 1100 },
  "distance_sensor": { "min": 2,   "max": 400 },
  "light_sensor":    { "min": 1,   "max": 65535 }
}
```

C expresses a sensor read through this declaration and an ordinary direct call:

```c
int sensor_read(const char *name);
int temperature = sensor_read("temp_sensor");
```

No Clang changes or custom C syntax are needed. The pass retrieves the literal
name from the global byte array in LLVM IR and looks up its interval.
Unknown names and nonliteral arguments receive no known interval.

These bounds are declared guarantees about the integer returned by this API.
Units and scaling must agree with the application's driver; the pass does not
check them. A physical operating range is not automatically a guarantee about
all driver return values: failures, sentinels, initialization, and invalid
measurements must be accounted for before applying a specification.

The loader accepts the documented flat format, with min followed by max and
an optional nonnegative max_delta_per_sample after max. That optional field
is stored but has no optimization effect. This regex-based loader is not a
general JSON parser: keep the documented field order, simple unescaped names,
and signed 64-bit integer bounds. It does not fully validate malformed JSON,
reject duplicate names, or gracefully handle every numeric conversion error.

The pass defaults to spec/sensors.json relative to its working directory.
For direct opt invocations, select another file with -sensor-spec=/absolute/path.
The wrapper scripts run the pass from the repository root and use the default.

## Pipeline and manual commands

```text
C source
  -> Clang frontend (lexing, parsing, semantic analysis)
  -> LLVM IR
  -> mem2reg
  -> baseline: simplifycfg -> dce
  -> ours: sensor-range-elim -> simplifycfg -> dce
  -> optional Clang backend -> host object files
```

Exact commands for a small demonstration:

```bash
clang-18 -S -emit-llvm -O0 -Xclang -disable-O0-optnone \
  tests/c/dead_low_bound.c -o /tmp/dead-low-bound.ll

opt-18 -passes='mem2reg,simplifycfg,dce' \
  /tmp/dead-low-bound.ll -S -o /tmp/dead-low-bound.base.ll

opt-18 -load-pass-plugin=build/SensorReaperPass.so \
  -passes='mem2reg,sensor-range-elim,simplifycfg,dce' \
  -sensor-range-verbose /tmp/dead-low-bound.ll \
  -S -o /tmp/dead-low-bound.opt.ll
```

disable-O0-optnone prevents Clang from tagging functions so optimization passes
skip them. mem2reg promotes local stack variables to SSA values, exposing use-def
chains and phi nodes. Both pipelines begin with the same unoptimized IR and
differ only by the custom pass. Avoid -O1/-O2 preprocessing when attributing the
effect to SensorReaper.

## Analysis and transformations

1. Seed a function-local map from direct sensor_read calls to declared intervals.
2. Visit reachable blocks in reverse post-order, computing supported result
   intervals from operand intervals.
3. Join select arms and phi incoming values with interval union.
4. Repeat until stable, with a cap of 16 traversals. Missing input information
   remains unknown; cyclic ranges can therefore remain unknown.
5. If the cap is reached, discard derived ranges and skip transformations.
6. Replace supported integer results with constants when their range is [c, c].
7. Decide supported integer comparisons only when both intervals prove the result.
8. Let simplifycfg and dce remove the resulting dead control flow and instructions.

Supported operations include integer constants, add/sub/mul, scalar integer
sext/zext/trunc, select, and integer phi joins. Endpoints are int64_t, with wider
temporary arithmetic for overflow checks. Potential signed-width overflow yields
unknown. Zero extension is tracked only for nonnegative source ranges; truncation
only when the entire interval fits the signed destination type.

Comparisons support eq/ne and signed ordering; unsigned ordering is considered
only when both intervals are nonnegative. Overlapping intervals usually produce
no decision. The pass does not refine facts on individual branch edges.

Enable -sensor-range-verbose to see sensor seeds, inferred intervals, comparison
proofs, constant substitutions, and per-function summaries. A proof of a false
comparison and removal of a branch are separate events: cleanup passes perform
the actual CFG deletion.

## Script interfaces and generated files

Build the plugin:

```bash
bash scripts/build.sh
```

Generate one fixture's pipeline outputs and optionally render them:

```bash
output=$(bash scripts/run_pipeline.sh tests/c/dead_low_bound.c)
bash scripts/visualize_cfg.sh "$output"
```

The pipeline prints its output directory on stdout for reuse by other scripts.
An optional second argument selects a reusable output directory; its named
pipeline files will be overwritten. Without that argument, each run gets a
unique directory under results/pipelines/.

Files include input.ll, before.ll, after.ll, ast.txt, and proofs.txt.
The visualizer accepts this directory, exports the existing IR with LLVM's
dot-cfg pass, and renders DOT files using Graphviz. It creates a fresh cfg.*
subdirectory containing before/ and after/ SVGs and DOTs.

The AST is a text dump of the original C syntax. CFG diagrams show LLVM basic
blocks and branch edges before and after optimization. Start with dead_low_bound
for a small diagram, then use the greenhouse demo to show large-scale pruning.

Run assertions independently:

```bash
python3 scripts/check_tests.py
python3 scripts/check_tests.py --output /tmp/sensorreaper-checks
```

The checker requires every C fixture to have an explicit expectation. It checks
baseline error-call presence before checking removal, preserves live paths per
function, checks selected range diagnostics and constant folding, and compiles
the two standalone C++ tests. Run Python normally: -O disables its assertions.

Environment overrides include LLVM_CONFIG and BUILD_DIR for building;
SENSOR_PLUGIN, CLANG, and OPT for pipelines; and CXX for standalone unit tests.
Use absolute paths for custom build/plugin directories, and matching LLVM tools.
An existing CMake build directory retains its previously selected compiler.

## Tests and their interpretation

- dead_low_bound / dead_high_bound: impossible temperature thresholds.
- redundant_validation: always-valid two-sided sensor bounds.
- arithmetic_chain: addition propagation followed by branch folding.
- sensor_seed_demo: direct sensor identification and seeding.
- interval_propagation_demo: arithmetic and supported cast diagnostics.
- phi_merge: union of humidity and temperature ranges; currently diagnostic-only.
- constant_folding: zero multiplication becomes a constant return while preserving
  the potentially effectful sensor call.
- live_threshold: a threshold within the legal range retains its alarm path.
- unknown_sensor: an unlisted sensor retains its alarm path.
- unknown_input_and_overflow: separate functions exercise unknown parameters and
  possible signed overflow; neither comparison is folded by this pass.
- realistic_esp32_style: six impossible checks plus live actuator decisions.
- looping_greenhouse_supervisor: 22 impossible checks inside a repeated control
  cycle; four live control decisions and the loop condition remain.

The loop fixture demonstrates pruning inside a loop. It does not demonstrate
precise induction-variable bounds or temporal constraints between samples.
The overflow fixture tests conservative analysis, not runtime behavior of C
signed overflow, which is undefined. These are compiler fixtures without main
functions; hardware calls are declarations. No linking stubs or firmware runtime
are provided, and no actual ESP32 deployment is performed.

The current suite has 13 C fixtures and two C++ tests. Additional coverage is
still desirable for standalone distance equality, comparison after a phi join,
select, unsigned predicates, unsafe casts, and adversarial specification input.
Passing these tests is not a general correctness proof for arbitrary LLVM IR.

## Evaluation and reading the results

evaluate.py builds the plugin, runs every C fixture through the shared pipeline,
and compiles both IR versions with clang -O0 -c. It writes results/results.csv
and results/results.md. Each run preserves IR, proof logs, and before.o/after.o
under a unique results/evaluation.* directory. The summary reports represent
the latest run.

Each test has four metric rows:

- conditional_branches: number of br i1 instructions.
- instructions: nonempty, noncomment, nonlabel lines within function bodies.
  This matches current single-line scalar fixtures; recognized multiline
  constructs make this metric n/a. It is not a general-purpose LLVM IR parser.
- basic_blocks: explicit block labels plus implicit entry blocks.
- text_bytes: sum of .text and .text.* section sizes from llvm-size -A or size -A.

Reduction is baseline minus ours. Percentage reduction divides by baseline;
zero baseline or unavailable measurements produce n/a. Negative reduction means
growth. Proven-true/false counts are totals across a test's functions and repeat
on each metric row: do not add those repeated totals together.

One recorded LLVM 18.1.8 x86-64 greenhouse run measured:

```text
Metric                  Baseline   Ours   Saved   Saved %
conditional_branches          27      5      22    81.48%
instructions                 179     41     138    77.09%
basic_blocks                  60     16      44    73.33%
text_bytes                  1512    319    1193    78.90%
```

These are measured fixture results, not expected constants in the evaluator.
Compiler versions, targets, and backend choices may change the numbers.

.text is the machine-code section inside the object, not its total file size,
RAM consumption, or execution speed. Objects are unlinked host artifacts;
measurements are not ESP32 code sizes, energy savings, or CoSense results.
The evaluator measures effects; check_tests.py separately asserts correctness.

## Connection to the compiler-design syllabus

Module 1: Clang supplies source analysis and lexical analysis. SpecLoader reads
a restricted specification format; it is not a formal tokenizing C lexer.

Modules 2 and 3: Clang supplies parsing. This project does not implement LL/LR
tables, shift-reduce parsing, ambiguity elimination, or error recovery. ast.txt
can illustrate frontend syntax structure.

Module 4: LLVM IR supplies typed intermediate instructions, SSA values, basic
blocks, and CFGs. Operand-to-result interval computation resembles synthesized
attributes in an S-attributed definition. LLVM IR is related to three-address
intermediate code, but it is not a custom quadruple/triple implementation.
Cast analysis uses types; it is not a full source-language type checker.

Module 5: the main contribution is interval dataflow analysis enabling comparison
folding, constant substitution, CFG simplification, and dead-code elimination.
The analysis spans blocks within one function. Local value numbering, loop
unrolling, live-variable analysis, global code placement, and a custom code
generator are not implemented. Clang's backend performs machine-code generation.

## Relationship to CoSense and limitations

CoSense couples sensor information described in the Newton DSL with LLVM
analysis. Its broader design includes range propagation across functions,
more operators and types, function specialization, type compression, condition
simplification, and constant substitution.

SensorReaper replaces the DSL integration with flat JSON plus named direct
function calls, uses integer intervals within individual functions, and focuses
on comparison folding and singleton substitution. Its tests and visualizations
are independent teaching demonstrations.

Current limitations include handwritten specs; no real datasheet parsing;
no units, calibration, accuracy model, or guaranteed fault handling; no
interprocedural propagation; no floating-point analysis; no path refinement;
no bitwise/modulo/division analysis; no precise loop-counter analysis; and no
sampling-rate or rate-of-change optimization. The constant-string extractor
targets ordinary direct literal calls, not general pointer-offset reasoning.
The prototype has not been validated for arbitrary vector IR or unusual call
signatures. Declared bounds must fit the sensor API's integer representation.

## Troubleshooting

- Missing FFI/terminfo C checks: CMake must enable both C and CXX languages,
  even though the pass source is C++.
- LibEdit not found: this message did not prevent the tested configuration from
  building; distinguish it from an actual CMake error.
- C++ headers missing: install g++ (including standard-library development
  headers) and verify the selected compiler.
- Plugin load/version error: rebuild using the LLVM development package that
  matches opt. Do not mix major versions.
- No pruning: check the sensor name, spec path, verbose proofs, mem2reg, and
  disable-O0-optnone. A live condition should remain.
- Images do not open: omit --no-open, install xdg-utils, and run in a desktop
  session. Open the generated SVG paths manually; viewer.log records errors.
- Large CFG: begin with the small fixture; SVGs can be zoomed in a viewer.
- No executable produced: fixtures are analyzed and compiled to objects, not
  linked with sensor implementations.
- CMake files in the source directory: future builds should use -S . -B build;
  the scripts do not delete existing user files or caches.

## Reference

Pei Mu, Nikolaos Mavrogeorgis, Christos Vasiladiotis, Vasileios Tsoutsouras,
Orestis Kaparounakis, Phillip Stanley-Marbell, and Antonio Barbalace.
2024. *CoSense: Compiler Optimizations using Sensor Technical Specifications.*
Proceedings of the 33rd ACM SIGPLAN International Conference on Compiler
Construction (CC '24), pp. 73-85.
[DOI: 10.1145/3640537.3641576](https://doi.org/10.1145/3640537.3641576).
