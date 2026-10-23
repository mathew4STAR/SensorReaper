; ModuleID = '/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/results/pipelines/looping_greenhouse_supervisor.Bm8HUe/input.ll'
source_filename = "/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/tests/c/looping_greenhouse_supervisor.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [12 x i8] c"temp_sensor\00", align 1
@.str.1 = private unnamed_addr constant [16 x i8] c"humidity_sensor\00", align 1
@.str.2 = private unnamed_addr constant [16 x i8] c"pressure_sensor\00", align 1
@.str.3 = private unnamed_addr constant [16 x i8] c"distance_sensor\00", align 1
@.str.4 = private unnamed_addr constant [13 x i8] c"light_sensor\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @run_greenhouse_supervisor(i32 noundef %0, i32 noundef %1) #0 {
  br label %3

3:                                                ; preds = %27, %2
  %.01 = phi i32 [ 0, %2 ], [ %.01, %27 ]
  %.0 = phi i32 [ 0, %2 ], [ %28, %27 ]
  %4 = icmp slt i32 %.0, %0
  br i1 %4, label %5, label %29

5:                                                ; preds = %3
  %6 = call i32 @sensor_read(ptr noundef @.str)
  %7 = call i32 @sensor_read(ptr noundef @.str.1)
  %8 = call i32 @sensor_read(ptr noundef @.str.2)
  %9 = call i32 @sensor_read(ptr noundef @.str.3)
  %10 = call i32 @sensor_read(ptr noundef @.str.4)
  %11 = icmp sgt i32 %6, 50
  %12 = icmp ne i32 %1, 0
  %or.cond = or i1 %11, %12
  br i1 %or.cond, label %13, label %14

13:                                               ; preds = %5
  call void @fan_on()
  call void @alarm()
  br label %15

14:                                               ; preds = %5
  call void @fan_off()
  br label %15

15:                                               ; preds = %14, %13
  %16 = icmp slt i32 %7, 30
  br i1 %16, label %17, label %18

17:                                               ; preds = %15
  call void @mist_on()
  br label %19

18:                                               ; preds = %15
  call void @mist_off()
  br label %19

19:                                               ; preds = %18, %17
  %20 = icmp slt i32 %8, 900
  br i1 %20, label %21, label %22

21:                                               ; preds = %19
  call void @vents_open()
  br label %23

22:                                               ; preds = %19
  call void @vents_close()
  br label %23

23:                                               ; preds = %22, %21
  %24 = icmp slt i32 %10, 100
  br i1 %24, label %25, label %26

25:                                               ; preds = %23
  call void @grow_lights_on()
  br label %27

26:                                               ; preds = %23
  call void @grow_lights_off()
  br label %27

27:                                               ; preds = %26, %25
  call void @record_cycle(i32 noundef %.0, i32 noundef %6, i32 noundef %7, i32 noundef %8, i32 noundef %9, i32 noundef %10)
  %28 = add nsw i32 %.0, 1
  br label %3, !llvm.loop !6

29:                                               ; preds = %3
  ret i32 %.01
}

declare i32 @sensor_read(ptr noundef) #1

declare void @err(i32 noundef) #1

declare void @fan_on() #1

declare void @alarm() #1

declare void @fan_off() #1

declare void @mist_on() #1

declare void @mist_off() #1

declare void @vents_open() #1

declare void @vents_close() #1

declare void @grow_lights_on() #1

declare void @grow_lights_off() #1

declare void @record_cycle(i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef) #1

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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
