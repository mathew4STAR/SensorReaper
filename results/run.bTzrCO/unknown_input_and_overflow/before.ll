; ModuleID = '/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/results/run.bTzrCO/unknown_input_and_overflow/input.ll'
source_filename = "/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/tests/c/unknown_input_and_overflow.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [12 x i8] c"temp_sensor\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @mixed_with_parameter(i32 noundef %0) #0 {
  %2 = call i32 @sensor_read(ptr noundef @.str)
  %3 = add nsw i32 %2, %0
  %4 = icmp sgt i32 %3, 200
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  call void @alarm()
  br label %6

6:                                                ; preds = %1, %5
  %.0 = phi i32 [ 1, %5 ], [ 0, %1 ]
  ret i32 %.0
}

declare i32 @sensor_read(ptr noundef) #1

declare void @alarm() #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @possible_overflow() #0 {
  %1 = call i32 @sensor_read(ptr noundef @.str)
  %2 = add nsw i32 %1, 2147483647
  %3 = icmp sgt i32 %2, 0
  br i1 %3, label %4, label %5

4:                                                ; preds = %0
  call void @alarm()
  br label %5

5:                                                ; preds = %0, %4
  %.0 = phi i32 [ 1, %4 ], [ 0, %0 ]
  ret i32 %.0
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 18.1.8 (++20240731024944+3b5b5c1ec4a3-1~exp1~20240731145000.144)"}
