; ModuleID = '/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/tests/c/realistic_esp32_style.c'
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
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %9 = call i32 @sensor_read(ptr noundef @.str)
  store i32 %9, ptr %4, align 4
  %10 = call i32 @sensor_read(ptr noundef @.str.1)
  store i32 %10, ptr %5, align 4
  %11 = call i32 @sensor_read(ptr noundef @.str.2)
  store i32 %11, ptr %6, align 4
  %12 = call i32 @sensor_read(ptr noundef @.str.3)
  store i32 %12, ptr %7, align 4
  %13 = call i32 @sensor_read(ptr noundef @.str.4)
  store i32 %13, ptr %8, align 4
  %14 = load i32, ptr %4, align 4
  %15 = icmp slt i32 %14, -100
  br i1 %15, label %16, label %17

16:                                               ; preds = %1
  call void @err()
  store i32 -1, ptr %2, align 4
  br label %66

17:                                               ; preds = %1
  %18 = load i32, ptr %4, align 4
  %19 = icmp sgt i32 %18, 200
  br i1 %19, label %20, label %21

20:                                               ; preds = %17
  call void @err()
  store i32 -2, ptr %2, align 4
  br label %66

21:                                               ; preds = %17
  %22 = load i32, ptr %5, align 4
  %23 = icmp sgt i32 %22, 120
  br i1 %23, label %24, label %25

24:                                               ; preds = %21
  call void @err()
  store i32 -3, ptr %2, align 4
  br label %66

25:                                               ; preds = %21
  %26 = load i32, ptr %6, align 4
  %27 = icmp slt i32 %26, 250
  br i1 %27, label %28, label %29

28:                                               ; preds = %25
  call void @err()
  store i32 -4, ptr %2, align 4
  br label %66

29:                                               ; preds = %25
  %30 = load i32, ptr %7, align 4
  %31 = icmp slt i32 %30, 1
  br i1 %31, label %32, label %33

32:                                               ; preds = %29
  call void @err()
  store i32 -5, ptr %2, align 4
  br label %66

33:                                               ; preds = %29
  %34 = load i32, ptr %8, align 4
  %35 = icmp eq i32 %34, 0
  br i1 %35, label %36, label %37

36:                                               ; preds = %33
  call void @err()
  store i32 -6, ptr %2, align 4
  br label %66

37:                                               ; preds = %33
  %38 = load i32, ptr %4, align 4
  %39 = icmp sgt i32 %38, 50
  br i1 %39, label %43, label %40

40:                                               ; preds = %37
  %41 = load i32, ptr %3, align 4
  %42 = icmp ne i32 %41, 0
  br i1 %42, label %43, label %44

43:                                               ; preds = %40, %37
  call void @fan_on()
  call void @alarm()
  br label %45

44:                                               ; preds = %40
  call void @fan_off()
  br label %45

45:                                               ; preds = %44, %43
  %46 = load i32, ptr %5, align 4
  %47 = icmp sge i32 %46, 75
  br i1 %47, label %48, label %49

48:                                               ; preds = %45
  call void @dehumidifier_on()
  br label %50

49:                                               ; preds = %45
  call void @dehumidifier_off()
  br label %50

50:                                               ; preds = %49, %48
  %51 = load i32, ptr %6, align 4
  %52 = icmp slt i32 %51, 900
  br i1 %52, label %53, label %54

53:                                               ; preds = %50
  call void @vent_on()
  br label %55

54:                                               ; preds = %50
  call void @vent_off()
  br label %55

55:                                               ; preds = %54, %53
  %56 = load i32, ptr %8, align 4
  %57 = icmp slt i32 %56, 100
  br i1 %57, label %58, label %59

58:                                               ; preds = %55
  call void @brighten_lights()
  br label %60

59:                                               ; preds = %55
  call void @dim_lights()
  br label %60

60:                                               ; preds = %59, %58
  %61 = load i32, ptr %4, align 4
  %62 = load i32, ptr %5, align 4
  %63 = load i32, ptr %6, align 4
  %64 = load i32, ptr %7, align 4
  %65 = load i32, ptr %8, align 4
  call void @publish_environment(i32 noundef %61, i32 noundef %62, i32 noundef %63, i32 noundef %64, i32 noundef %65)
  store i32 0, ptr %2, align 4
  br label %66

66:                                               ; preds = %60, %36, %32, %28, %24, %20, %16
  %67 = load i32, ptr %2, align 4
  ret i32 %67
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
