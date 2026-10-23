; ModuleID = '/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/results/evaluation.neklhx98/interval_propagation_demo/input.ll'
source_filename = "/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/tests/c/interval_propagation_demo.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [12 x i8] c"temp_sensor\00", align 1
@.str.1 = private unnamed_addr constant [16 x i8] c"humidity_sensor\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @transform_temperature() #0 {
  %1 = call i32 @sensor_read(ptr noundef @.str)
  %2 = add nsw i32 %1, %1
  %3 = sub nsw i32 %2, 10
  %4 = mul nsw i32 %3, 2
  ret i32 %4
}

declare i32 @sensor_read(ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @extend_temperature() #0 {
  %1 = call i32 @sensor_read(ptr noundef @.str)
  %2 = sext i32 %1 to i64
  ret i64 %2
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @extend_humidity() #0 {
  %1 = call i32 @sensor_read(ptr noundef @.str.1)
  %2 = sext i32 %1 to i64
  ret i64 %2
}

; Function Attrs: noinline nounwind uwtable
define dso_local signext i16 @narrow_temperature() #0 {
  %1 = call i32 @sensor_read(ptr noundef @.str)
  %2 = trunc i32 %1 to i16
  ret i16 %2
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
