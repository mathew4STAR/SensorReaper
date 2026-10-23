; ModuleID = '/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/results/run.mTIGvo/realistic_esp32_style/input.ll'
source_filename = "/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/tests/c/realistic_esp32_style.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [12 x i8] c"temp_sensor\00", align 1
@.str.1 = private unnamed_addr constant [16 x i8] c"humidity_sensor\00", align 1
@.str.2 = private unnamed_addr constant [16 x i8] c"pressure_sensor\00", align 1
@.str.3 = private unnamed_addr constant [16 x i8] c"distance_sensor\00", align 1
@.str.4 = private unnamed_addr constant [13 x i8] c"light_sensor\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @run_environment_controller(i32 noundef %0) #0 {
  %2 = call i32 @sensor_read(ptr noundef @.str)
  %3 = call i32 @sensor_read(ptr noundef @.str.1)
  %4 = call i32 @sensor_read(ptr noundef @.str.2)
  %5 = call i32 @sensor_read(ptr noundef @.str.3)
  %6 = call i32 @sensor_read(ptr noundef @.str.4)
  %7 = icmp sgt i32 %2, 50
  %8 = icmp ne i32 %0, 0
  %or.cond = or i1 %7, %8
  br i1 %or.cond, label %9, label %10

9:                                                ; preds = %1
  call void @fan_on()
  call void @alarm()
  br label %11

10:                                               ; preds = %1
  call void @fan_off()
  br label %11

11:                                               ; preds = %10, %9
  %12 = icmp sge i32 %3, 75
  br i1 %12, label %13, label %14

13:                                               ; preds = %11
  call void @dehumidifier_on()
  br label %15

14:                                               ; preds = %11
  call void @dehumidifier_off()
  br label %15

15:                                               ; preds = %14, %13
  %16 = icmp slt i32 %4, 900
  br i1 %16, label %17, label %18

17:                                               ; preds = %15
  call void @vent_on()
  br label %19

18:                                               ; preds = %15
  call void @vent_off()
  br label %19

19:                                               ; preds = %18, %17
  %20 = icmp slt i32 %6, 100
  br i1 %20, label %21, label %22

21:                                               ; preds = %19
  call void @brighten_lights()
  br label %23

22:                                               ; preds = %19
  call void @dim_lights()
  br label %23

23:                                               ; preds = %22, %21
  call void @publish_environment(i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, i32 noundef %6)
  ret i32 0
}

declare i32 @sensor_read(ptr noundef) #1

declare void @err() #1

declare void @fan_on() #1

declare void @alarm() #1

declare void @fan_off() #1

declare void @dehumidifier_on() #1

declare void @dehumidifier_off() #1

declare void @vent_on() #1

declare void @vent_off() #1

declare void @brighten_lights() #1

declare void @dim_lights() #1

declare void @publish_environment(i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef) #1

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
