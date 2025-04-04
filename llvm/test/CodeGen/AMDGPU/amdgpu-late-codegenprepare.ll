; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S -mtriple=amdgcn-amd-amdhsa -mcpu=gfx900 -amdgpu-late-codegenprepare %s | FileCheck %s -check-prefix=GFX9
; RUN: opt -S -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1200 -amdgpu-late-codegenprepare %s | FileCheck %s -check-prefix=GFX12
; RUN: opt -S -mtriple=amdgcn-amd-amdhsa -mcpu=gfx900 -passes=amdgpu-late-codegenprepare %s | FileCheck %s -check-prefix=GFX9

; Make sure we don't crash when trying to create a bitcast between
; address spaces
define amdgpu_kernel void @constant_from_offset_cast_generic_null() {
; GFX9-LABEL: @constant_from_offset_cast_generic_null(
; GFX9-NEXT:    [[TMP1:%.*]] = load i32, ptr addrspace(4) getelementptr (i8, ptr addrspace(4) addrspacecast (ptr null to ptr addrspace(4)), i64 4), align 4
; GFX9-NEXT:    [[TMP2:%.*]] = lshr i32 [[TMP1]], 16
; GFX9-NEXT:    [[TMP3:%.*]] = trunc i32 [[TMP2]] to i8
; GFX9-NEXT:    store i8 [[TMP3]], ptr addrspace(1) poison, align 1
; GFX9-NEXT:    ret void
;
; GFX12-LABEL: @constant_from_offset_cast_generic_null(
; GFX12-NEXT:    [[LOAD:%.*]] = load i8, ptr addrspace(4) getelementptr inbounds (i8, ptr addrspace(4) addrspacecast (ptr null to ptr addrspace(4)), i64 6), align 1
; GFX12-NEXT:    store i8 [[LOAD]], ptr addrspace(1) poison, align 1
; GFX12-NEXT:    ret void
;
  %load = load i8, ptr addrspace(4) getelementptr inbounds (i8, ptr addrspace(4) addrspacecast (ptr null to ptr addrspace(4)), i64 6), align 1
  store i8 %load, ptr addrspace(1) poison
  ret void
}

define amdgpu_kernel void @constant_from_offset_cast_global_null() {
; GFX9-LABEL: @constant_from_offset_cast_global_null(
; GFX9-NEXT:    [[TMP1:%.*]] = load i32, ptr addrspace(4) getelementptr (i8, ptr addrspace(4) addrspacecast (ptr addrspace(1) null to ptr addrspace(4)), i64 4), align 4
; GFX9-NEXT:    [[TMP2:%.*]] = lshr i32 [[TMP1]], 16
; GFX9-NEXT:    [[TMP3:%.*]] = trunc i32 [[TMP2]] to i8
; GFX9-NEXT:    store i8 [[TMP3]], ptr addrspace(1) poison, align 1
; GFX9-NEXT:    ret void
;
; GFX12-LABEL: @constant_from_offset_cast_global_null(
; GFX12-NEXT:    [[LOAD:%.*]] = load i8, ptr addrspace(4) getelementptr inbounds (i8, ptr addrspace(4) addrspacecast (ptr addrspace(1) null to ptr addrspace(4)), i64 6), align 1
; GFX12-NEXT:    store i8 [[LOAD]], ptr addrspace(1) poison, align 1
; GFX12-NEXT:    ret void
;
  %load = load i8, ptr addrspace(4) getelementptr inbounds (i8, ptr addrspace(4) addrspacecast (ptr addrspace(1) null to ptr addrspace(4)), i64 6), align 1
  store i8 %load, ptr addrspace(1) poison
  ret void
}

@gv = unnamed_addr addrspace(1) global [64 x i8] poison, align 4

define amdgpu_kernel void @constant_from_offset_cast_global_gv() {
; GFX9-LABEL: @constant_from_offset_cast_global_gv(
; GFX9-NEXT:    [[TMP1:%.*]] = load i32, ptr addrspace(4) getelementptr (i8, ptr addrspace(4) addrspacecast (ptr addrspace(1) @gv to ptr addrspace(4)), i64 4), align 4
; GFX9-NEXT:    [[TMP2:%.*]] = lshr i32 [[TMP1]], 16
; GFX9-NEXT:    [[TMP3:%.*]] = trunc i32 [[TMP2]] to i8
; GFX9-NEXT:    store i8 [[TMP3]], ptr addrspace(1) poison, align 1
; GFX9-NEXT:    ret void
;
; GFX12-LABEL: @constant_from_offset_cast_global_gv(
; GFX12-NEXT:    [[LOAD:%.*]] = load i8, ptr addrspace(4) getelementptr inbounds (i8, ptr addrspace(4) addrspacecast (ptr addrspace(1) @gv to ptr addrspace(4)), i64 6), align 1
; GFX12-NEXT:    store i8 [[LOAD]], ptr addrspace(1) poison, align 1
; GFX12-NEXT:    ret void
;
  %load = load i8, ptr addrspace(4) getelementptr inbounds (i8, ptr addrspace(4) addrspacecast (ptr addrspace(1) @gv to ptr addrspace(4)), i64 6), align 1
  store i8 %load, ptr addrspace(1) poison
  ret void
}

define amdgpu_kernel void @constant_from_offset_cast_generic_inttoptr() {
; GFX9-LABEL: @constant_from_offset_cast_generic_inttoptr(
; GFX9-NEXT:    [[TMP1:%.*]] = load i32, ptr addrspace(4) getelementptr (i8, ptr addrspace(4) addrspacecast (ptr inttoptr (i64 128 to ptr) to ptr addrspace(4)), i64 4), align 4
; GFX9-NEXT:    [[TMP2:%.*]] = lshr i32 [[TMP1]], 16
; GFX9-NEXT:    [[TMP3:%.*]] = trunc i32 [[TMP2]] to i8
; GFX9-NEXT:    store i8 [[TMP3]], ptr addrspace(1) poison, align 1
; GFX9-NEXT:    ret void
;
; GFX12-LABEL: @constant_from_offset_cast_generic_inttoptr(
; GFX12-NEXT:    [[LOAD:%.*]] = load i8, ptr addrspace(4) getelementptr inbounds (i8, ptr addrspace(4) addrspacecast (ptr inttoptr (i64 128 to ptr) to ptr addrspace(4)), i64 6), align 1
; GFX12-NEXT:    store i8 [[LOAD]], ptr addrspace(1) poison, align 1
; GFX12-NEXT:    ret void
;
  %load = load i8, ptr addrspace(4) getelementptr inbounds (i8, ptr addrspace(4) addrspacecast (ptr inttoptr (i64 128 to ptr) to ptr addrspace(4)), i64 6), align 1
  store i8 %load, ptr addrspace(1) poison
  ret void
}

define amdgpu_kernel void @constant_from_inttoptr() {
; GFX9-LABEL: @constant_from_inttoptr(
; GFX9-NEXT:    [[LOAD:%.*]] = load i8, ptr addrspace(4) inttoptr (i64 128 to ptr addrspace(4)), align 4
; GFX9-NEXT:    store i8 [[LOAD]], ptr addrspace(1) poison, align 1
; GFX9-NEXT:    ret void
;
; GFX12-LABEL: @constant_from_inttoptr(
; GFX12-NEXT:    [[LOAD:%.*]] = load i8, ptr addrspace(4) inttoptr (i64 128 to ptr addrspace(4)), align 1
; GFX12-NEXT:    store i8 [[LOAD]], ptr addrspace(1) poison, align 1
; GFX12-NEXT:    ret void
;
  %load = load i8, ptr addrspace(4) inttoptr (i64 128 to ptr addrspace(4)), align 1
  store i8 %load, ptr addrspace(1) poison
  ret void
}

define void @broken_phi() {
; GFX9-LABEL: @broken_phi(
; GFX9-NEXT:  bb:
; GFX9-NEXT:    br label [[BB1:%.*]]
; GFX9:       bb1:
; GFX9-NEXT:    [[I:%.*]] = phi <4 x i8> [ splat (i8 1), [[BB:%.*]] ], [ [[I8:%.*]], [[BB7:%.*]] ]
; GFX9-NEXT:    br i1 false, label [[BB3:%.*]], label [[BB2:%.*]]
; GFX9:       bb2:
; GFX9-NEXT:    br label [[BB3]]
; GFX9:       bb3:
; GFX9-NEXT:    [[I4:%.*]] = phi <4 x i8> [ zeroinitializer, [[BB2]] ], [ [[I]], [[BB1]] ]
; GFX9-NEXT:    br i1 false, label [[BB7]], label [[BB5:%.*]]
; GFX9:       bb5:
; GFX9-NEXT:    [[I6:%.*]] = call <4 x i8> @llvm.smax.v4i8(<4 x i8> [[I4]], <4 x i8> zeroinitializer)
; GFX9-NEXT:    br label [[BB7]]
; GFX9:       bb7:
; GFX9-NEXT:    [[I8]] = phi <4 x i8> [ zeroinitializer, [[BB5]] ], [ zeroinitializer, [[BB3]] ]
; GFX9-NEXT:    br label [[BB1]]
;
; GFX12-LABEL: @broken_phi(
; GFX12-NEXT:  bb:
; GFX12-NEXT:    br label [[BB1:%.*]]
; GFX12:       bb1:
; GFX12-NEXT:    [[I:%.*]] = phi <4 x i8> [ splat (i8 1), [[BB:%.*]] ], [ [[I8:%.*]], [[BB7:%.*]] ]
; GFX12-NEXT:    br i1 false, label [[BB3:%.*]], label [[BB2:%.*]]
; GFX12:       bb2:
; GFX12-NEXT:    br label [[BB3]]
; GFX12:       bb3:
; GFX12-NEXT:    [[I4:%.*]] = phi <4 x i8> [ zeroinitializer, [[BB2]] ], [ [[I]], [[BB1]] ]
; GFX12-NEXT:    br i1 false, label [[BB7]], label [[BB5:%.*]]
; GFX12:       bb5:
; GFX12-NEXT:    [[I6:%.*]] = call <4 x i8> @llvm.smax.v4i8(<4 x i8> [[I4]], <4 x i8> zeroinitializer)
; GFX12-NEXT:    br label [[BB7]]
; GFX12:       bb7:
; GFX12-NEXT:    [[I8]] = phi <4 x i8> [ zeroinitializer, [[BB5]] ], [ zeroinitializer, [[BB3]] ]
; GFX12-NEXT:    br label [[BB1]]
;
bb:
  br label %bb1
bb1:
  %i = phi <4 x i8> [ <i8 1, i8 1, i8 1, i8 1>, %bb ], [ %i8, %bb7 ]
  br i1 false, label %bb3, label %bb2
bb2:
  br label %bb3
bb3:
  %i4 = phi <4 x i8> [ zeroinitializer, %bb2 ], [ %i, %bb1 ]
  br i1 false, label %bb7, label %bb5
bb5:
  %i6 = call <4 x i8> @llvm.smax.v4i8(<4 x i8> %i4, <4 x i8> zeroinitializer)
  br label %bb7
bb7:
  %i8 = phi <4 x i8> [ zeroinitializer, %bb5 ], [ zeroinitializer, %bb3 ]
  br label %bb1
}
