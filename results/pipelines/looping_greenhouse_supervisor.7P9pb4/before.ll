; ModuleID = '/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/results/pipelines/looping_greenhouse_supervisor.7P9pb4/input.ll'
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

3:                                                ; preds = %121, %2
  %.01 = phi i32 [ 0, %2 ], [ %.22, %121 ]
  %.0 = phi i32 [ 0, %2 ], [ %122, %121 ]
  %4 = icmp slt i32 %.0, %0
  br i1 %4, label %5, label %123

5:                                                ; preds = %3
  %6 = call i32 @sensor_read(ptr noundef @.str)
  %7 = call i32 @sensor_read(ptr noundef @.str.1)
  %8 = call i32 @sensor_read(ptr noundef @.str.2)
  %9 = call i32 @sensor_read(ptr noundef @.str.3)
  %10 = call i32 @sensor_read(ptr noundef @.str.4)
  %11 = icmp slt i32 %6, -100
  br i1 %11, label %12, label %14

12:                                               ; preds = %5
  call void @err(i32 noundef 1)
  %13 = add nsw i32 %.01, 1
  br label %14

14:                                               ; preds = %12, %5
  %.1 = phi i32 [ %13, %12 ], [ %.01, %5 ]
  %15 = icmp sgt i32 %6, 200
  br i1 %15, label %16, label %18

16:                                               ; preds = %14
  call void @err(i32 noundef 2)
  %17 = add nsw i32 %.1, 1
  br label %18

18:                                               ; preds = %16, %14
  %.2 = phi i32 [ %17, %16 ], [ %.1, %14 ]
  %19 = icmp slt i32 %7, 0
  br i1 %19, label %20, label %22

20:                                               ; preds = %18
  call void @err(i32 noundef 3)
  %21 = add nsw i32 %.2, 1
  br label %22

22:                                               ; preds = %20, %18
  %.3 = phi i32 [ %21, %20 ], [ %.2, %18 ]
  %23 = icmp sgt i32 %7, 100
  br i1 %23, label %24, label %26

24:                                               ; preds = %22
  call void @err(i32 noundef 4)
  %25 = add nsw i32 %.3, 1
  br label %26

26:                                               ; preds = %24, %22
  %.4 = phi i32 [ %25, %24 ], [ %.3, %22 ]
  %27 = icmp slt i32 %8, 300
  br i1 %27, label %28, label %30

28:                                               ; preds = %26
  call void @err(i32 noundef 5)
  %29 = add nsw i32 %.4, 1
  br label %30

30:                                               ; preds = %28, %26
  %.5 = phi i32 [ %29, %28 ], [ %.4, %26 ]
  %31 = icmp sgt i32 %8, 1100
  br i1 %31, label %32, label %34

32:                                               ; preds = %30
  call void @err(i32 noundef 6)
  %33 = add nsw i32 %.5, 1
  br label %34

34:                                               ; preds = %32, %30
  %.6 = phi i32 [ %33, %32 ], [ %.5, %30 ]
  %35 = icmp slt i32 %9, 2
  br i1 %35, label %36, label %38

36:                                               ; preds = %34
  call void @err(i32 noundef 7)
  %37 = add nsw i32 %.6, 1
  br label %38

38:                                               ; preds = %36, %34
  %.7 = phi i32 [ %37, %36 ], [ %.6, %34 ]
  %39 = icmp sgt i32 %9, 400
  br i1 %39, label %40, label %42

40:                                               ; preds = %38
  call void @err(i32 noundef 8)
  %41 = add nsw i32 %.7, 1
  br label %42

42:                                               ; preds = %40, %38
  %.8 = phi i32 [ %41, %40 ], [ %.7, %38 ]
  %43 = icmp slt i32 %10, 1
  br i1 %43, label %44, label %46

44:                                               ; preds = %42
  call void @err(i32 noundef 9)
  %45 = add nsw i32 %.8, 1
  br label %46

46:                                               ; preds = %44, %42
  %.9 = phi i32 [ %45, %44 ], [ %.8, %42 ]
  %47 = icmp sgt i32 %10, 65535
  br i1 %47, label %48, label %50

48:                                               ; preds = %46
  call void @err(i32 noundef 10)
  %49 = add nsw i32 %.9, 1
  br label %50

50:                                               ; preds = %48, %46
  %.10 = phi i32 [ %49, %48 ], [ %.9, %46 ]
  %51 = add nsw i32 %6, %6
  %52 = sub nsw i32 %6, 10
  %53 = add nsw i32 %7, 5
  %54 = sub nsw i32 %8, 50
  %55 = mul nsw i32 %9, 2
  %56 = sub nsw i32 %10, 1
  %57 = icmp sgt i32 %51, 170
  br i1 %57, label %58, label %60

58:                                               ; preds = %50
  call void @err(i32 noundef 11)
  %59 = add nsw i32 %.10, 1
  br label %60

60:                                               ; preds = %58, %50
  %.11 = phi i32 [ %59, %58 ], [ %.10, %50 ]
  %61 = icmp slt i32 %51, -80
  br i1 %61, label %62, label %64

62:                                               ; preds = %60
  call void @err(i32 noundef 12)
  %63 = add nsw i32 %.11, 1
  br label %64

64:                                               ; preds = %62, %60
  %.12 = phi i32 [ %63, %62 ], [ %.11, %60 ]
  %65 = icmp sgt i32 %52, 75
  br i1 %65, label %66, label %68

66:                                               ; preds = %64
  call void @err(i32 noundef 13)
  %67 = add nsw i32 %.12, 1
  br label %68

68:                                               ; preds = %66, %64
  %.13 = phi i32 [ %67, %66 ], [ %.12, %64 ]
  %69 = icmp slt i32 %52, -50
  br i1 %69, label %70, label %72

70:                                               ; preds = %68
  call void @err(i32 noundef 14)
  %71 = add nsw i32 %.13, 1
  br label %72

72:                                               ; preds = %70, %68
  %.14 = phi i32 [ %71, %70 ], [ %.13, %68 ]
  %73 = icmp sgt i32 %53, 105
  br i1 %73, label %74, label %76

74:                                               ; preds = %72
  call void @err(i32 noundef 15)
  %75 = add nsw i32 %.14, 1
  br label %76

76:                                               ; preds = %74, %72
  %.15 = phi i32 [ %75, %74 ], [ %.14, %72 ]
  %77 = icmp slt i32 %53, 5
  br i1 %77, label %78, label %80

78:                                               ; preds = %76
  call void @err(i32 noundef 16)
  %79 = add nsw i32 %.15, 1
  br label %80

80:                                               ; preds = %78, %76
  %.16 = phi i32 [ %79, %78 ], [ %.15, %76 ]
  %81 = icmp sgt i32 %54, 1050
  br i1 %81, label %82, label %84

82:                                               ; preds = %80
  call void @err(i32 noundef 17)
  %83 = add nsw i32 %.16, 1
  br label %84

84:                                               ; preds = %82, %80
  %.17 = phi i32 [ %83, %82 ], [ %.16, %80 ]
  %85 = icmp slt i32 %54, 250
  br i1 %85, label %86, label %88

86:                                               ; preds = %84
  call void @err(i32 noundef 18)
  %87 = add nsw i32 %.17, 1
  br label %88

88:                                               ; preds = %86, %84
  %.18 = phi i32 [ %87, %86 ], [ %.17, %84 ]
  %89 = icmp sgt i32 %55, 800
  br i1 %89, label %90, label %92

90:                                               ; preds = %88
  call void @err(i32 noundef 19)
  %91 = add nsw i32 %.18, 1
  br label %92

92:                                               ; preds = %90, %88
  %.19 = phi i32 [ %91, %90 ], [ %.18, %88 ]
  %93 = icmp slt i32 %55, 4
  br i1 %93, label %94, label %96

94:                                               ; preds = %92
  call void @err(i32 noundef 20)
  %95 = add nsw i32 %.19, 1
  br label %96

96:                                               ; preds = %94, %92
  %.20 = phi i32 [ %95, %94 ], [ %.19, %92 ]
  %97 = icmp sgt i32 %56, 65534
  br i1 %97, label %98, label %100

98:                                               ; preds = %96
  call void @err(i32 noundef 21)
  %99 = add nsw i32 %.20, 1
  br label %100

100:                                              ; preds = %98, %96
  %.21 = phi i32 [ %99, %98 ], [ %.20, %96 ]
  %101 = icmp slt i32 %56, 0
  br i1 %101, label %102, label %104

102:                                              ; preds = %100
  call void @err(i32 noundef 22)
  %103 = add nsw i32 %.21, 1
  br label %104

104:                                              ; preds = %102, %100
  %.22 = phi i32 [ %103, %102 ], [ %.21, %100 ]
  %105 = icmp sgt i32 %6, 50
  %106 = icmp ne i32 %1, 0
  %or.cond = or i1 %105, %106
  br i1 %or.cond, label %107, label %108

107:                                              ; preds = %104
  call void @fan_on()
  call void @alarm()
  br label %109

108:                                              ; preds = %104
  call void @fan_off()
  br label %109

109:                                              ; preds = %108, %107
  %110 = icmp slt i32 %7, 30
  br i1 %110, label %111, label %112

111:                                              ; preds = %109
  call void @mist_on()
  br label %113

112:                                              ; preds = %109
  call void @mist_off()
  br label %113

113:                                              ; preds = %112, %111
  %114 = icmp slt i32 %8, 900
  br i1 %114, label %115, label %116

115:                                              ; preds = %113
  call void @vents_open()
  br label %117

116:                                              ; preds = %113
  call void @vents_close()
  br label %117

117:                                              ; preds = %116, %115
  %118 = icmp slt i32 %10, 100
  br i1 %118, label %119, label %120

119:                                              ; preds = %117
  call void @grow_lights_on()
  br label %121

120:                                              ; preds = %117
  call void @grow_lights_off()
  br label %121

121:                                              ; preds = %120, %119
  call void @record_cycle(i32 noundef %.0, i32 noundef %6, i32 noundef %7, i32 noundef %8, i32 noundef %9, i32 noundef %10)
  %122 = add nsw i32 %.0, 1
  br label %3, !llvm.loop !6

123:                                              ; preds = %3
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
