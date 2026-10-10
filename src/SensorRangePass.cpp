#include "Interval.h"
#include "SpecLoader.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

using namespace llvm;

namespace {

// Selects the flat JSON file that supplies sensor names and their safe ranges.
cl::opt<std::string> SensorSpecPath(
    "sensor-spec", cl::desc("Path to the sensor range JSON specification"),
    cl::init("spec/sensors.json"), cl::value_desc("path"));

// Enables messages that show which calls received ranges from the specification.
cl::opt<bool> SensorRangeVerbose(
    "sensor-range-verbose", cl::desc("Print sensor-range pass diagnostics"),
    cl::init(false));

// Extracts a string literal from an opaque-pointer argument, if one is available.
static std::optional<std::string> getStringLiteral(const Value *argument) {
  // Remove pointer casts, then walk constant GEPs back to their global string.
  const Value *base = argument->stripPointerCasts();
  while (const auto *gep = dyn_cast<GEPOperator>(base))
    base = gep->getPointerOperand()->stripPointerCasts();

  // A Clang string literal is stored as a global constant byte array.
  const auto *global = dyn_cast<GlobalVariable>(base);
  if (!global || !global->hasInitializer())
    return std::nullopt;
  const auto *data = dyn_cast<ConstantDataArray>(global->getInitializer());
  if (!data || !data->isCString())
    return std::nullopt;
  // getAsCString returns the literal contents without the terminating null byte.
  return data->getAsCString().str();
}

// Defines the function pass that seeds ranges from direct sensor_read calls.
class SensorRangePass : public PassInfoMixin<SensorRangePass> {
public:
  // Finds spec-known sensor reads but does not yet transform this function.
  PreservedAnalyses run(Function &function, FunctionAnalysisManager &analysisManager) {
    SpecLoader loader;
    std::string error;
    if (!loader.load(SensorSpecPath, error)) {
      errs() << "sensor-range-elim: " << error << '\n';
      return PreservedAnalyses::all();
    }

    // This map becomes the initial fact set for interval propagation through llvm ir.
    DenseMap<const Value *, Interval> seededRanges;
    for (Instruction &instruction : instructions(function)) {
      const auto *call = dyn_cast<CallInst>(&instruction);
      if (!call || !call->getCalledFunction() ||
          call->getCalledFunction()->getName() != "sensor_read" ||
          call->arg_empty())
        continue;

      const auto sensorName = getStringLiteral(call->getArgOperand(0));
      if (!sensorName)
        continue;
      const auto limits = loader.find(*sensorName);
      if (!limits)
        continue;

      // Associate this call result with the interval guaranteed by the spec.
      seededRanges.insert({call, Interval::closed(limits->min, limits->max)});
      if (SensorRangeVerbose)
        errs() << "sensor-range-elim: seeded " << *sensorName << " as ["
               << limits->min << ", " << limits->max << "] in "
               << function.getName() << '\n';
    }

    if (SensorRangeVerbose)
      errs() << "sensor-range-elim: reads seeded in " << function.getName()
             << ": " << seededRanges.size() << '\n';

    // No IR changes occur until the later comparison-folding step.
    (void)analysisManager;
    return PreservedAnalyses::all();
  }
};

} // namespace

// Exposes the plugin metadata and new-pass-manager registration hook to opt.
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "SensorRangePass", LLVM_VERSION_STRING,
          // Registers our textual pipeline name when opt constructs a pipeline.
          [](PassBuilder &passBuilder) {
            passBuilder.registerPipelineParsingCallback(
                // Adds this pass only when the pipeline contains its exact name.
                [](StringRef name, FunctionPassManager &functionPassManager,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (name != "sensor-range-elim")
                    return false;
                  functionPassManager.addPass(SensorRangePass());
                  return true;
                });
          }};
}
