; RUN: mlir-translate -import-llvm -split-input-file %s | FileCheck %s

; CHECK-LABEL: llvm.metadata @__llvm_global_metadata {
; CHECK-DAG:    llvm.tbaa_root @[[R0:tbaa_root_[0-9]+]] {id = "Simple C/C++ TBAA"}
; CHECK-DAG:    llvm.tbaa_type_desc @[[D0:tbaa_type_desc_[0-9]+]] {id = "scalar type", members = {<@[[R0]], 0>}}
; CHECK-DAG:    llvm.tbaa_tag @[[T0:tbaa_tag_[0-9]+]] {access_type = @[[D0]], base_type = @[[D0]], offset = 0 : i64}
; CHECK-DAG:    llvm.tbaa_root @[[R1:tbaa_root_[0-9]+]] {id = "Other language TBAA"}
; CHECK-DAG:    llvm.tbaa_type_desc @[[D1:tbaa_type_desc_[0-9]+]] {id = "other scalar type", members = {<@[[R1]], 0>}}
; CHECK-DAG:    llvm.tbaa_tag @[[T1:tbaa_tag_[0-9]+]] {access_type = @[[D1]], base_type = @[[D1]], offset = 0 : i64}
; CHECK-NEXT:  }
; CHECK:       llvm.func @tbaa1
; CHECK:         llvm.store %{{.*}}, %{{.*}} {
; CHECK-SAME:        tbaa = [@__llvm_global_metadata::@[[T0]]]
; CHECK-SAME:    } : i8, !llvm.ptr
; CHECK:         llvm.store %{{.*}}, %{{.*}} {
; CHECK-SAME:        tbaa = [@__llvm_global_metadata::@[[T1]]]
; CHECK-SAME:    } : i8, !llvm.ptr
define dso_local void @tbaa1(ptr %0, ptr %1) {
  store i8 1, ptr %0, align 4, !tbaa !0
  store i8 1, ptr %1, align 4, !tbaa !3
  ret void
}

!0 = !{!1, !1, i64 0}
!1 = !{!"scalar type", !2, i64 0}
!2 = !{!"Simple C/C++ TBAA"}

!3 = !{!4, !4, i64 0}
!4 = !{!"other scalar type", !5, i64 0}
!5 = !{!"Other language TBAA"}

; // -----

; CHECK-LABEL: llvm.metadata @__llvm_global_metadata {
; CHECK-NEXT:    llvm.tbaa_root @[[R0:tbaa_root_[0-9]+]] {id = "Simple C/C++ TBAA"}
; CHECK-NEXT:    llvm.tbaa_tag @[[T0:tbaa_tag_[0-9]+]] {access_type = @[[D1:tbaa_type_desc_[0-9]+]], base_type = @[[D2:tbaa_type_desc_[0-9]+]], offset = 8 : i64}
; CHECK-NEXT:    llvm.tbaa_type_desc @[[D1]] {id = "long long", members = {<@[[D0:tbaa_type_desc_[0-9]+]], 0>}}
; CHECK-NEXT:    llvm.tbaa_type_desc @[[D0]] {id = "omnipotent char", members = {<@[[R0]], 0>}}
; CHECK-NEXT:    llvm.tbaa_type_desc @[[D2]] {id = "agg2_t", members = {<@[[D1]], 0>, <@[[D1]], 8>}}
; CHECK-NEXT:    llvm.tbaa_tag @[[T1:tbaa_tag_[0-9]+]] {access_type = @[[D3:tbaa_type_desc_[0-9]+]], base_type = @[[D4:tbaa_type_desc_[0-9]+]], offset = 0 : i64}
; CHECK-NEXT:    llvm.tbaa_type_desc @[[D3]] {id = "int", members = {<@[[D0]], 0>}}
; CHECK-NEXT:    llvm.tbaa_type_desc @[[D4]] {id = "agg1_t", members = {<@[[D3]], 0>, <@[[D3]], 4>}}
; CHECK-NEXT:  }
; CHECK:       llvm.func @tbaa2
; CHECK:         llvm.load %{{.*}} {
; CHECK-SAME:        tbaa = [@__llvm_global_metadata::@[[T0]]]
; CHECK-SAME:    } : !llvm.ptr -> i64
; CHECK:         llvm.store %{{.*}}, %{{.*}} {
; CHECK-SAME:        tbaa = [@__llvm_global_metadata::@[[T1]]]
; CHECK-SAME:    } : i32, !llvm.ptr
%struct.agg2_t = type { i64, i64 }
%struct.agg1_t = type { i32, i32 }

define dso_local void @tbaa2(ptr %0, ptr %1) {
  %3 = getelementptr inbounds %struct.agg2_t, ptr %1, i32 0, i32 1
  %4 = load i64, ptr %3, align 8, !tbaa !6
  %5 = trunc i64 %4 to i32
  %6 = getelementptr inbounds %struct.agg1_t, ptr %0, i32 0, i32 0
  store i32 %5, ptr %6, align 4, !tbaa !11
  ret void
}

!6 = !{!7, !8, i64 8}
!7 = !{!"agg2_t", !8, i64 0, !8, i64 8}
!8 = !{!"long long", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!12, !13, i64 0}
!12 = !{!"agg1_t", !13, i64 0, !13, i64 4}
!13 = !{!"int", !9, i64 0}

; // -----

; CHECK-LABEL: llvm.func @supported_ops
define void @supported_ops(ptr %arg1, float %arg2, i32 %arg3, i32 %arg4) {
  ; CHECK: llvm.load {{.*}}tbaa =
  %1 = load i32, ptr %arg1, !tbaa !0
  ; CHECK: llvm.store {{.*}}tbaa =
  store i32 %1, ptr %arg1, !tbaa !0
  ; CHECK: llvm.atomicrmw {{.*}}tbaa =
  %2 = atomicrmw fmax ptr %arg1, float %arg2 acquire, !tbaa !0
  ; CHECK: llvm.cmpxchg {{.*}}tbaa =
  %3 = cmpxchg ptr %arg1, i32 %arg3, i32 %arg4 monotonic seq_cst, !tbaa !0
  ret void
}

!0 = !{!1, !1, i64 0}
!1 = !{!"scalar type", !2, i64 0}
!2 = !{!"Simple C/C++ TBAA"}
