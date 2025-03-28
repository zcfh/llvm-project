//===- bolt/Passes/Aligner.cpp - Pass for optimal code alignment ----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the AlignerPass class.
//
//===----------------------------------------------------------------------===//

#include "bolt/Passes/Aligner.h"
#include "bolt/Core/ParallelUtilities.h"

#define DEBUG_TYPE "bolt-aligner"

using namespace llvm;

namespace opts {

extern cl::OptionCategory BoltOptCategory;

extern cl::opt<bool> AlignBlocks;
extern cl::opt<bool> PreserveBlocksAlignment;
extern cl::opt<unsigned> AlignFunctions;

static cl::opt<unsigned> AlignBlocksMinSize(
    "align-blocks-min-size",
    cl::desc("minimal size of the basic block that should be aligned"),
    cl::init(0), cl::ZeroOrMore, cl::Hidden, cl::cat(BoltOptCategory));

static cl::opt<unsigned> AlignBlocksThreshold(
    "align-blocks-threshold",
    cl::desc(
        "align only blocks with frequency larger than containing function "
        "execution frequency specified in percent. E.g. 1000 means aligning "
        "blocks that are 10 times more frequently executed than the "
        "containing function."),
    cl::init(800), cl::Hidden, cl::cat(BoltOptCategory));

static cl::opt<unsigned> AlignFunctionsMaxBytes(
    "align-functions-max-bytes",
    cl::desc("maximum number of bytes to use to align functions"), cl::init(32),
    cl::cat(BoltOptCategory));

static cl::opt<unsigned>
    BlockAlignment("block-alignment",
                   cl::desc("boundary to use for alignment of basic blocks"),
                   cl::init(16), cl::ZeroOrMore, cl::cat(BoltOptCategory));

static cl::opt<bool>
    UseCompactAligner("use-compact-aligner",
                      cl::desc("Use compact approach for aligning functions"),
                      cl::init(true), cl::cat(BoltOptCategory));

} // end namespace opts

namespace llvm {
namespace bolt {

// Align function to the specified byte-boundary (typically, 64) offsetting
// the fuction by not more than the corresponding value
static void alignMaxBytes(BinaryFunction &Function) {
  Function.setAlignment(opts::AlignFunctions);
  Function.setMaxAlignmentBytes(opts::AlignFunctionsMaxBytes);
  Function.setMaxColdAlignmentBytes(opts::AlignFunctionsMaxBytes);
}

// Align function to the specified byte-boundary (typically, 64) offsetting
// the fuction by not more than the minimum over
// -- the size of the function
// -- the specified number of bytes
static void alignCompact(BinaryFunction &Function,
                         const MCCodeEmitter *Emitter) {
  const BinaryContext &BC = Function.getBinaryContext();
  size_t HotSize = 0;
  size_t ColdSize = 0;

  for (const BinaryBasicBlock &BB : Function)
    if (BB.isSplit())
      ColdSize += BC.computeCodeSize(BB.begin(), BB.end(), Emitter);
    else
      HotSize += BC.computeCodeSize(BB.begin(), BB.end(), Emitter);

  Function.setAlignment(opts::AlignFunctions);
  if (HotSize > 0)
    Function.setMaxAlignmentBytes(
      std::min(size_t(opts::AlignFunctionsMaxBytes), HotSize));

  // using the same option, max-align-bytes, both for cold and hot parts of the
  // functions, as aligning cold functions typically does not affect performance
  if (ColdSize > 0)
    Function.setMaxColdAlignmentBytes(
      std::min(size_t(opts::AlignFunctionsMaxBytes), ColdSize));
}

void AlignerPass::alignBlocks(BinaryFunction &Function,
                              const MCCodeEmitter *Emitter) {
  if (!Function.hasValidProfile() || !Function.isSimple())
    return;

  const BinaryContext &BC = Function.getBinaryContext();

  const uint64_t FuncCount =
      std::max<uint64_t>(1, Function.getKnownExecutionCount());
  BinaryBasicBlock *PrevBB = nullptr;
  for (BinaryBasicBlock *BB : Function.getLayout().blocks()) {
    uint64_t Count = BB->getKnownExecutionCount();

    if (Count <= FuncCount * opts::AlignBlocksThreshold / 100) {
      PrevBB = BB;
      continue;
    }

    uint64_t FTCount = 0;
    if (PrevBB && PrevBB->getFallthrough() == BB)
      FTCount = PrevBB->getBranchInfo(*BB).Count;

    PrevBB = BB;

    if (Count < FTCount * 2)
      continue;

    const uint64_t BlockSize =
        BC.computeCodeSize(BB->begin(), BB->end(), Emitter);
    const uint64_t BytesToUse =
        std::min<uint64_t>(opts::BlockAlignment - 1, BlockSize);

    if (opts::AlignBlocksMinSize && BlockSize < opts::AlignBlocksMinSize)
      continue;

    BB->setAlignment(opts::BlockAlignment);
    BB->setAlignmentMaxBytes(BytesToUse);

    // Update stats.
    LLVM_DEBUG(
      std::unique_lock<llvm::sys::RWMutex> Lock(AlignHistogramMtx);
      AlignHistogram[BytesToUse]++;
      AlignedBlocksCount += BB->getKnownExecutionCount();
    );
  }
}

Error AlignerPass::runOnFunctions(BinaryContext &BC) {
  if (!BC.HasRelocations)
    return Error::success();

  AlignHistogram.resize(opts::BlockAlignment);

  ParallelUtilities::WorkFuncTy WorkFun = [&](BinaryFunction &BF) {
    // Create a separate MCCodeEmitter to allow lock free execution
    BinaryContext::IndependentCodeEmitter Emitter =
        BC.createIndependentMCCodeEmitter();

    if (opts::UseCompactAligner)
      alignCompact(BF, Emitter.MCE.get());
    else
      alignMaxBytes(BF);

    if (opts::AlignBlocks && !opts::PreserveBlocksAlignment)
      alignBlocks(BF, Emitter.MCE.get());
  };

  ParallelUtilities::runOnEachFunction(
      BC, ParallelUtilities::SchedulingPolicy::SP_TRIVIAL, WorkFun,
      ParallelUtilities::PredicateTy(nullptr), "AlignerPass");

  LLVM_DEBUG(
    dbgs() << "BOLT-DEBUG: max bytes per basic block alignment distribution:\n";
    for (unsigned I = 1; I < AlignHistogram.size(); ++I)
      dbgs() << "  " << I << " : " << AlignHistogram[I] << '\n';

    dbgs() << "BOLT-DEBUG: total execution count of aligned blocks: "
           << AlignedBlocksCount << '\n';
  );
  return Error::success();
}

} // end namespace bolt
} // end namespace llvm
