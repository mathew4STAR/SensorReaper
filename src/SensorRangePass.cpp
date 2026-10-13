#include "Interval.h"
#include "SpecLoader.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/PostOrderIterator.h"
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

// Gets a known interval for a value, treating an untracked value as unknown.
static Interval getInterval(const Value *value,
                            const DenseMap<const Value *, Interval> &ranges) {
  // ConstantInt returns its signed value exactly when its type is at most i64.
  if (const auto *constant = dyn_cast<ConstantInt>(value)) {
    if (constant->getBitWidth() <= 64)
      return Interval::closed(constant->getSExtValue(), constant->getSExtValue());
    return Interval::unknown();
  }
  const auto found = ranges.find(value);
  return found == ranges.end() ? Interval::unknown() : found->second;
}

// Computes one instruction's interval from intervals already known for its operands.
static Interval evaluateInstruction(
    const Instruction &instruction,
    const DenseMap<const Value *, Interval> &ranges) {
  // A phi may select any incoming control-flow value, so join all incoming ranges.
  if (const auto *phi = dyn_cast<PHINode>(&instruction)) {
    if (!phi->getType()->isIntegerTy() || phi->getNumIncomingValues() == 0)
      return Interval::unknown();
    Interval merged = getInterval(phi->getIncomingValue(0), ranges);
    for (unsigned index = 1; merged.isKnown() &&
                             index < phi->getNumIncomingValues();
         ++index)
      merged = Interval::unite(
          merged, getInterval(phi->getIncomingValue(index), ranges));
    return merged;
  }

  // Handle the arithmetic operations supported by this project.
  if (const auto *binary = dyn_cast<BinaryOperator>(&instruction)) {
    if (!binary->getType()->isIntegerTy())
      return Interval::unknown();
    const unsigned width = binary->getType()->getIntegerBitWidth();
    const Interval left = getInterval(binary->getOperand(0), ranges);
    const Interval right = getInterval(binary->getOperand(1), ranges);
    switch (binary->getOpcode()) {
    case Instruction::Add:
      return Interval::add(left, right, width);
    case Instruction::Sub:
      return Interval::sub(left, right, width);
    case Instruction::Mul:
      return Interval::mul(left, right, width);
    default:
      return Interval::unknown();
    }
  }

  // A sign extension preserves signed numeric values in a wider type.
  if (const auto *cast = dyn_cast<SExtInst>(&instruction))
    return Interval::sext(getInterval(cast->getOperand(0), ranges),
                          cast->getSrcTy()->getIntegerBitWidth(),
                          cast->getDestTy()->getIntegerBitWidth());

  // A zero extension is safe only when the source interval is non-negative.
  if (const auto *cast = dyn_cast<ZExtInst>(&instruction))
    return Interval::zext(getInterval(cast->getOperand(0), ranges),
                          cast->getSrcTy()->getIntegerBitWidth(),
                          cast->getDestTy()->getIntegerBitWidth());

  // A truncation is safe only if its full input interval fits the smaller type.
  if (const auto *cast = dyn_cast<TruncInst>(&instruction))
    return Interval::trunc(getInterval(cast->getOperand(0), ranges),
                           cast->getDestTy()->getIntegerBitWidth());

  // A select can produce either arm, so join both arm ranges.
  if (const auto *select = dyn_cast<SelectInst>(&instruction))
    return Interval::unite(getInterval(select->getTrueValue(), ranges),
                           getInterval(select->getFalseValue(), ranges));

  return Interval::unknown();
}

// Reports whether evaluation supports this instruction in the current project scope.
static bool supportsInterval(const Instruction &instruction) {
  return isa<PHINode>(instruction) || isa<BinaryOperator>(instruction) ||
         isa<SExtInst>(instruction) || isa<ZExtInst>(instruction) ||
         isa<TruncInst>(instruction) || isa<SelectInst>(instruction);
}

// Decides an integer comparison only when both operand intervals prove its result.
static std::optional<bool> decideComparison(CmpInst::Predicate predicate,
                                            const Interval &left,
                                            const Interval &right) {
  if (!left.isKnown() || !right.isKnown())
    return std::nullopt;

  const bool disjoint = left.max() < right.min() || right.max() < left.min();
  const bool sameConstant = left.min() == left.max() &&
                            right.min() == right.max() &&
                            left.min() == right.min();
  switch (predicate) {
  case CmpInst::ICMP_EQ:
    return sameConstant ? std::optional<bool>(true)
                        : (disjoint ? std::optional<bool>(false) : std::nullopt);
  case CmpInst::ICMP_NE:
    return sameConstant ? std::optional<bool>(false)
                        : (disjoint ? std::optional<bool>(true) : std::nullopt);
  case CmpInst::ICMP_SLT:
  case CmpInst::ICMP_ULT:
    return left.max() < right.min() ? std::optional<bool>(true)
                                     : (left.min() >= right.max()
                                            ? std::optional<bool>(false)
                                            : std::nullopt);
  case CmpInst::ICMP_SLE:
  case CmpInst::ICMP_ULE:
    return left.max() <= right.min() ? std::optional<bool>(true)
                                      : (left.min() > right.max()
                                             ? std::optional<bool>(false)
                                             : std::nullopt);
  case CmpInst::ICMP_SGT:
  case CmpInst::ICMP_UGT:
    return left.min() > right.max() ? std::optional<bool>(true)
                                     : (left.max() <= right.min()
                                            ? std::optional<bool>(false)
                                            : std::nullopt);
  case CmpInst::ICMP_SGE:
  case CmpInst::ICMP_UGE:
    return left.min() >= right.max() ? std::optional<bool>(true)
                                      : (left.max() < right.min()
                                             ? std::optional<bool>(false)
                                             : std::nullopt);
  default:
    return std::nullopt;
  }
}

// Prints a value as an LLVM operand, such as %temperature or -100.
static std::string valueText(const Value &value) {
  std::string text;
  raw_string_ostream stream(text);
  value.printAsOperand(stream, false);
  return stream.str();
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

    // This map holds seeded facts and propagated results for this function.
    DenseMap<const Value *, Interval> ranges;
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
      ranges.insert({call, Interval::closed(limits->min, limits->max)});
      if (SensorRangeVerbose)
        errs() << "sensor-range-elim: seeded " << *sensorName << " as ["
               << limits->min << ", " << limits->max << "] in "
               << function.getName() << '\n';
    }

    if (SensorRangeVerbose)
      errs() << "sensor-range-elim: reads seeded in " << function.getName()
             << ": " << ranges.size() << '\n';

    // Retain sensor facts so non-convergence can safely discard derived results.
    const DenseMap<const Value *, Interval> seededRanges = ranges;
    const unsigned readsSeeded = ranges.size();
    constexpr unsigned MaxIterations = 16;
    bool converged = false;
    for (unsigned iteration = 0; iteration < MaxIterations; ++iteration) {
      bool changed = false;
      // Reverse post-order visits predecessors before successors when possible.
      ReversePostOrderTraversal<Function *> rpo(&function);
      for (const BasicBlock *block : rpo) {
        for (const Instruction &instruction : *block) {
          if (!supportsInterval(instruction))
            continue;
          const Interval result = evaluateInstruction(instruction, ranges);
          const auto previous = ranges.find(&instruction);
          if (!result.isKnown()) {
            if (previous != ranges.end()) {
              ranges.erase(&instruction);
              changed = true;
            }
            continue;
          }
          if (previous != ranges.end() && previous->second.equals(result))
            continue;
          if (previous == ranges.end())
            ranges.insert({&instruction, result});
          else
            previous->second = result;
          changed = true;
          if (SensorRangeVerbose)
            errs() << "sensor-range-elim: inferred [" << result.min() << ", "
                   << result.max() << "] in " << function.getName() << '\n';
        }
      }
      if (!changed) {
        converged = true;
        break;
      }
    }

    if (!converged) {
      // Keep only sensor facts because an unconverged result is not trustworthy.
      ranges = seededRanges;
      if (SensorRangeVerbose)
        errs() << "sensor-range-elim: iteration cap reached in "
               << function.getName() << "; derived ranges discarded\n";
    }

    unsigned comparisonsTrue = 0;
    unsigned comparisonsFalse = 0;
    unsigned constantsFolded = 0;
    bool changedIr = false;
    if (converged) {
      // Replace a supported SSA result only when its interval has one value.
      for (Instruction &instruction : instructions(function)) {
        if (!supportsInterval(instruction) || !instruction.getType()->isIntegerTy())
          continue;
        const auto found = ranges.find(&instruction);
        if (found == ranges.end() || !found->second.isKnown() ||
            found->second.min() != found->second.max())
          continue;

        // ConstantInt creates an LLVM integer constant with this instruction's type.
        instruction.replaceAllUsesWith(ConstantInt::get(
            instruction.getType(), static_cast<uint64_t>(found->second.min()), true));
        changedIr = true;
        ++constantsFolded;
        if (SensorRangeVerbose)
          errs() << "sensor-range-elim: folded interval [" << found->second.min()
                 << ", " << found->second.max() << "] to a constant in "
                 << function.getName() << '\n';
      }

      for (Instruction &instruction : instructions(function)) {
        auto *comparison = dyn_cast<ICmpInst>(&instruction);
        if (!comparison)
          continue;
        const Interval left = getInterval(comparison->getOperand(0), ranges);
        const Interval right = getInterval(comparison->getOperand(1), ranges);
        if (!left.isKnown() || !right.isKnown())
          continue;
        const CmpInst::Predicate predicate = comparison->getPredicate();
        const bool isUnsigned = predicate == CmpInst::ICMP_ULT ||
                                predicate == CmpInst::ICMP_ULE ||
                                predicate == CmpInst::ICMP_UGT ||
                                predicate == CmpInst::ICMP_UGE;
        if (isUnsigned && (left.min() < 0 || right.min() < 0))
          continue;
        const auto decision = decideComparison(predicate, left, right);
        if (!decision)
          continue;

        // Replace all branch users with a constant i1; simplifycfg removes blocks.
        comparison->replaceAllUsesWith(
            ConstantInt::get(comparison->getType(), *decision ? 1 : 0));
        changedIr = true;
        if (*decision)
          ++comparisonsTrue;
        else
          ++comparisonsFalse;
        if (SensorRangeVerbose)
          errs() << "sensor-range-elim: icmp "
                 << CmpInst::getPredicateName(predicate) << " "
                 << valueText(*comparison->getOperand(0)) << ", "
                 << valueText(*comparison->getOperand(1)) << " is always "
                 << (*decision ? "true" : "false") << ": [" << left.min()
                 << ", " << left.max() << "] versus [" << right.min() << ", "
                 << right.max() << "]\n";
      }
    }
    if (SensorRangeVerbose)
      errs() << "sensor-range-elim: summary for " << function.getName()
             << ": reads seeded=" << readsSeeded
             << ", constants folded=" << constantsFolded
             << ", comparisons proven true=" << comparisonsTrue
             << ", comparisons proven false=" << comparisonsFalse << '\n';

    (void)analysisManager;
    return changedIr ? PreservedAnalyses::none() : PreservedAnalyses::all();
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
