; RUN: opt -passes='require<demanded-bits>,constraint-elimination,require<demanded-bits>' -disable-verify -verify-analysis-invalidation=false -debug-pass-manager -disable-output %s 2>&1 | FileCheck %s

; Check that constraint-elimination properly invalidates anlyses.

; FIXME: ssub simplification currently doesn't properly set the change status
;        after modifying the IR, which causes DemandedBits to be preserved.

; CHECK:      Running pass: RequireAnalysisPass
; CHECK-NEXT: Running analysis: DemandedBitsAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running analysis: AssumptionAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running analysis: TargetIRAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running analysis: DominatorTreeAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running pass: ConstraintEliminationPass on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running analysis: LoopAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running analysis: ScalarEvolutionAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running analysis: TargetLibraryAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running analysis: OptimizationRemarkEmitterAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Invalidating analysis: DemandedBitsAnalysis on ssub_no_overflow_due_to_or_conds
; CHECK-NEXT: Running pass: RequireAnalysisPass
; CHECK-NEXT: Running analysis: DemandedBitsAnalysis on ssub_no_overflow_due_to_or_conds

; CHECK-NEXT: Running pass: RequireAnalysisPass
; CHECK-NEXT: Running analysis: DemandedBitsAnalysis on uge_zext
; CHECK-NEXT: Running analysis: AssumptionAnalysis on uge_zext
; CHECK-NEXT: Running analysis: TargetIRAnalysis on uge_zext
; CHECK-NEXT: Running analysis: DominatorTreeAnalysis on uge_zext
; CHECK-NEXT: Running pass: ConstraintEliminationPass on uge_zext
; CHECK-NEXT: Running analysis: LoopAnalysis on uge_zext
; CHECK-NEXT: Running analysis: ScalarEvolutionAnalysis on uge_zext
; CHECK-NEXT: Running analysis: TargetLibraryAnalysis on uge_zext
; CHECK-NEXT: Running analysis: OptimizationRemarkEmitterAnalysis on uge_zext
; CHECK-NEXT: Invalidating analysis: DemandedBitsAnalysis on uge_zext
; CHECK-NEXT: Running pass: RequireAnalysisPass
; CHECK-NEXT: Running analysis: DemandedBitsAnalysis on uge_zext

; CHECK-NEXT: Running pass: RequireAnalysisPass
; CHECK-NEXT: Running analysis: DemandedBitsAnalysis on test_mul_const_nuw_unsigned_14
; CHECK-NEXT: Running analysis: AssumptionAnalysis on test_mul_const_nuw_unsigned_14
; CHECK-NEXT: Running analysis: TargetIRAnalysis on test_mul_const_nuw_unsigned_14
; CHECK-NEXT: Running analysis: DominatorTreeAnalysis on test_mul_const_nuw_unsigned_14
; CHECK-NEXT: Running pass: ConstraintEliminationPass on test_mul_const_nuw_unsigned_14
; CHECK-NEXT: Running analysis: LoopAnalysis on test_mul_const_nuw_unsigned_14
; CHECK-NEXT: Running analysis: ScalarEvolutionAnalysis on test_mul_const_nuw_unsigned_14
; CHECK-NEXT: Running analysis: TargetLibraryAnalysis on test_mul_const_nuw_unsigned_14
; CHECK-NEXT: Running analysis: OptimizationRemarkEmitterAnalysis on test_mul_const_nuw_unsigned_14

declare { i8, i1 } @llvm.ssub.with.overflow.i8(i8, i8)

define i8 @ssub_no_overflow_due_to_or_conds(i8 %a, i8 %b) {
entry:
  %c.1 = icmp sle i8 %b, %a
  %c.2 = icmp slt i8 %a, 0
  %or.cond = or i1 %c.2, %c.1
  br i1 %or.cond, label %exit.fail, label %math

math:
  %op = tail call { i8, i1 } @llvm.ssub.with.overflow.i8(i8 %b, i8 %a)
  %status = extractvalue { i8, i1 } %op, 1
  br i1 %status, label %exit.fail, label %exit.ok

exit.ok:
  %res = extractvalue { i8, i1 } %op, 0
  ret i8 %res

exit.fail:
  ret i8 0
}

declare void @use_res({ i8, i1 })


define i1 @uge_zext(i8 %x, i16 %y) {
entry:
  %x.ext = zext i8 %x to i16
  %c.1 = icmp uge i16 %x.ext, %y
  br i1 %c.1, label %bb1, label %bb2

bb1:
  %t.1 = icmp uge i16 %x.ext, %y
  ret i1 %t.1

bb2:
  ret i1 false
}

define i1 @test_mul_const_nuw_unsigned_14(i8 %start) {
  %start.mul.5 = mul nuw i8 %start, -5
  %c.0 = icmp ult i8 %start, %start.mul.5
  call void @llvm.assume(i1 %c.0)

  %start.mul.3 = mul nuw i8 %start, -3
  %t.1 = icmp ule i8 %start.mul.3, %start.mul.5
  ret i1 %t.1
}
