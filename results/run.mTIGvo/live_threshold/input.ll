; ModuleID = '/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/tests/c/live_threshold.c'
source_filename = "/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/tests/c/live_threshold.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [12 x i8] c"temp_sensor\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @live_threshold() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = call i32 @sensor_read(ptr noundef @.str)
  store i32 %3, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  %5 = icmp sgt i32 %4, 50
  br i1 %5, label %6, label %7

6:                                                ; preds = %0
  call void @alarm()
  store i32 1, ptr %1, align 4
  br label %8

7:                                                ; preds = %0
  store i32 0, ptr %1, align 4
  br label %8

8:                                                ; preds = %7, %6
  %9 = load i32, ptr %1, align 4
  ret i32 %9
}

declare i32 @sensor_read(ptr noundef) #1

declare void @alarm() #1

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
