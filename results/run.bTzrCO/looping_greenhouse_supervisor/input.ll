; ModuleID = '/home/mathew/Documents/ChatGPT/SensorProject/sensor-range-opt/tests/c/looping_greenhouse_supervisor.c'
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
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %18

18:                                               ; preds = %202, %2
  %19 = load i32, ptr %6, align 4
  %20 = load i32, ptr %3, align 4
  %21 = icmp slt i32 %19, %20
  br i1 %21, label %22, label %205

22:                                               ; preds = %18
  %23 = call i32 @sensor_read(ptr noundef @.str)
  store i32 %23, ptr %7, align 4
  %24 = call i32 @sensor_read(ptr noundef @.str.1)
  store i32 %24, ptr %8, align 4
  %25 = call i32 @sensor_read(ptr noundef @.str.2)
  store i32 %25, ptr %9, align 4
  %26 = call i32 @sensor_read(ptr noundef @.str.3)
  store i32 %26, ptr %10, align 4
  %27 = call i32 @sensor_read(ptr noundef @.str.4)
  store i32 %27, ptr %11, align 4
  %28 = load i32, ptr %7, align 4
  %29 = icmp slt i32 %28, -100
  br i1 %29, label %30, label %33

30:                                               ; preds = %22
  call void @err(i32 noundef 1)
  %31 = load i32, ptr %5, align 4
  %32 = add nsw i32 %31, 1
  store i32 %32, ptr %5, align 4
  br label %33

33:                                               ; preds = %30, %22
  %34 = load i32, ptr %7, align 4
  %35 = icmp sgt i32 %34, 200
  br i1 %35, label %36, label %39

36:                                               ; preds = %33
  call void @err(i32 noundef 2)
  %37 = load i32, ptr %5, align 4
  %38 = add nsw i32 %37, 1
  store i32 %38, ptr %5, align 4
  br label %39

39:                                               ; preds = %36, %33
  %40 = load i32, ptr %8, align 4
  %41 = icmp slt i32 %40, 0
  br i1 %41, label %42, label %45

42:                                               ; preds = %39
  call void @err(i32 noundef 3)
  %43 = load i32, ptr %5, align 4
  %44 = add nsw i32 %43, 1
  store i32 %44, ptr %5, align 4
  br label %45

45:                                               ; preds = %42, %39
  %46 = load i32, ptr %8, align 4
  %47 = icmp sgt i32 %46, 100
  br i1 %47, label %48, label %51

48:                                               ; preds = %45
  call void @err(i32 noundef 4)
  %49 = load i32, ptr %5, align 4
  %50 = add nsw i32 %49, 1
  store i32 %50, ptr %5, align 4
  br label %51

51:                                               ; preds = %48, %45
  %52 = load i32, ptr %9, align 4
  %53 = icmp slt i32 %52, 300
  br i1 %53, label %54, label %57

54:                                               ; preds = %51
  call void @err(i32 noundef 5)
  %55 = load i32, ptr %5, align 4
  %56 = add nsw i32 %55, 1
  store i32 %56, ptr %5, align 4
  br label %57

57:                                               ; preds = %54, %51
  %58 = load i32, ptr %9, align 4
  %59 = icmp sgt i32 %58, 1100
  br i1 %59, label %60, label %63

60:                                               ; preds = %57
  call void @err(i32 noundef 6)
  %61 = load i32, ptr %5, align 4
  %62 = add nsw i32 %61, 1
  store i32 %62, ptr %5, align 4
  br label %63

63:                                               ; preds = %60, %57
  %64 = load i32, ptr %10, align 4
  %65 = icmp slt i32 %64, 2
  br i1 %65, label %66, label %69

66:                                               ; preds = %63
  call void @err(i32 noundef 7)
  %67 = load i32, ptr %5, align 4
  %68 = add nsw i32 %67, 1
  store i32 %68, ptr %5, align 4
  br label %69

69:                                               ; preds = %66, %63
  %70 = load i32, ptr %10, align 4
  %71 = icmp sgt i32 %70, 400
  br i1 %71, label %72, label %75

72:                                               ; preds = %69
  call void @err(i32 noundef 8)
  %73 = load i32, ptr %5, align 4
  %74 = add nsw i32 %73, 1
  store i32 %74, ptr %5, align 4
  br label %75

75:                                               ; preds = %72, %69
  %76 = load i32, ptr %11, align 4
  %77 = icmp slt i32 %76, 1
  br i1 %77, label %78, label %81

78:                                               ; preds = %75
  call void @err(i32 noundef 9)
  %79 = load i32, ptr %5, align 4
  %80 = add nsw i32 %79, 1
  store i32 %80, ptr %5, align 4
  br label %81

81:                                               ; preds = %78, %75
  %82 = load i32, ptr %11, align 4
  %83 = icmp sgt i32 %82, 65535
  br i1 %83, label %84, label %87

84:                                               ; preds = %81
  call void @err(i32 noundef 10)
  %85 = load i32, ptr %5, align 4
  %86 = add nsw i32 %85, 1
  store i32 %86, ptr %5, align 4
  br label %87

87:                                               ; preds = %84, %81
  %88 = load i32, ptr %7, align 4
  %89 = load i32, ptr %7, align 4
  %90 = add nsw i32 %88, %89
  store i32 %90, ptr %12, align 4
  %91 = load i32, ptr %7, align 4
  %92 = sub nsw i32 %91, 10
  store i32 %92, ptr %13, align 4
  %93 = load i32, ptr %8, align 4
  %94 = add nsw i32 %93, 5
  store i32 %94, ptr %14, align 4
  %95 = load i32, ptr %9, align 4
  %96 = sub nsw i32 %95, 50
  store i32 %96, ptr %15, align 4
  %97 = load i32, ptr %10, align 4
  %98 = mul nsw i32 %97, 2
  store i32 %98, ptr %16, align 4
  %99 = load i32, ptr %11, align 4
  %100 = sub nsw i32 %99, 1
  store i32 %100, ptr %17, align 4
  %101 = load i32, ptr %12, align 4
  %102 = icmp sgt i32 %101, 170
  br i1 %102, label %103, label %106

103:                                              ; preds = %87
  call void @err(i32 noundef 11)
  %104 = load i32, ptr %5, align 4
  %105 = add nsw i32 %104, 1
  store i32 %105, ptr %5, align 4
  br label %106

106:                                              ; preds = %103, %87
  %107 = load i32, ptr %12, align 4
  %108 = icmp slt i32 %107, -80
  br i1 %108, label %109, label %112

109:                                              ; preds = %106
  call void @err(i32 noundef 12)
  %110 = load i32, ptr %5, align 4
  %111 = add nsw i32 %110, 1
  store i32 %111, ptr %5, align 4
  br label %112

112:                                              ; preds = %109, %106
  %113 = load i32, ptr %13, align 4
  %114 = icmp sgt i32 %113, 75
  br i1 %114, label %115, label %118

115:                                              ; preds = %112
  call void @err(i32 noundef 13)
  %116 = load i32, ptr %5, align 4
  %117 = add nsw i32 %116, 1
  store i32 %117, ptr %5, align 4
  br label %118

118:                                              ; preds = %115, %112
  %119 = load i32, ptr %13, align 4
  %120 = icmp slt i32 %119, -50
  br i1 %120, label %121, label %124

121:                                              ; preds = %118
  call void @err(i32 noundef 14)
  %122 = load i32, ptr %5, align 4
  %123 = add nsw i32 %122, 1
  store i32 %123, ptr %5, align 4
  br label %124

124:                                              ; preds = %121, %118
  %125 = load i32, ptr %14, align 4
  %126 = icmp sgt i32 %125, 105
  br i1 %126, label %127, label %130

127:                                              ; preds = %124
  call void @err(i32 noundef 15)
  %128 = load i32, ptr %5, align 4
  %129 = add nsw i32 %128, 1
  store i32 %129, ptr %5, align 4
  br label %130

130:                                              ; preds = %127, %124
  %131 = load i32, ptr %14, align 4
  %132 = icmp slt i32 %131, 5
  br i1 %132, label %133, label %136

133:                                              ; preds = %130
  call void @err(i32 noundef 16)
  %134 = load i32, ptr %5, align 4
  %135 = add nsw i32 %134, 1
  store i32 %135, ptr %5, align 4
  br label %136

136:                                              ; preds = %133, %130
  %137 = load i32, ptr %15, align 4
  %138 = icmp sgt i32 %137, 1050
  br i1 %138, label %139, label %142

139:                                              ; preds = %136
  call void @err(i32 noundef 17)
  %140 = load i32, ptr %5, align 4
  %141 = add nsw i32 %140, 1
  store i32 %141, ptr %5, align 4
  br label %142

142:                                              ; preds = %139, %136
  %143 = load i32, ptr %15, align 4
  %144 = icmp slt i32 %143, 250
  br i1 %144, label %145, label %148

145:                                              ; preds = %142
  call void @err(i32 noundef 18)
  %146 = load i32, ptr %5, align 4
  %147 = add nsw i32 %146, 1
  store i32 %147, ptr %5, align 4
  br label %148

148:                                              ; preds = %145, %142
  %149 = load i32, ptr %16, align 4
  %150 = icmp sgt i32 %149, 800
  br i1 %150, label %151, label %154

151:                                              ; preds = %148
  call void @err(i32 noundef 19)
  %152 = load i32, ptr %5, align 4
  %153 = add nsw i32 %152, 1
  store i32 %153, ptr %5, align 4
  br label %154

154:                                              ; preds = %151, %148
  %155 = load i32, ptr %16, align 4
  %156 = icmp slt i32 %155, 4
  br i1 %156, label %157, label %160

157:                                              ; preds = %154
  call void @err(i32 noundef 20)
  %158 = load i32, ptr %5, align 4
  %159 = add nsw i32 %158, 1
  store i32 %159, ptr %5, align 4
  br label %160

160:                                              ; preds = %157, %154
  %161 = load i32, ptr %17, align 4
  %162 = icmp sgt i32 %161, 65534
  br i1 %162, label %163, label %166

163:                                              ; preds = %160
  call void @err(i32 noundef 21)
  %164 = load i32, ptr %5, align 4
  %165 = add nsw i32 %164, 1
  store i32 %165, ptr %5, align 4
  br label %166

166:                                              ; preds = %163, %160
  %167 = load i32, ptr %17, align 4
  %168 = icmp slt i32 %167, 0
  br i1 %168, label %169, label %172

169:                                              ; preds = %166
  call void @err(i32 noundef 22)
  %170 = load i32, ptr %5, align 4
  %171 = add nsw i32 %170, 1
  store i32 %171, ptr %5, align 4
  br label %172

172:                                              ; preds = %169, %166
  %173 = load i32, ptr %7, align 4
  %174 = icmp sgt i32 %173, 50
  br i1 %174, label %178, label %175

175:                                              ; preds = %172
  %176 = load i32, ptr %4, align 4
  %177 = icmp ne i32 %176, 0
  br i1 %177, label %178, label %179

178:                                              ; preds = %175, %172
  call void @fan_on()
  call void @alarm()
  br label %180

179:                                              ; preds = %175
  call void @fan_off()
  br label %180

180:                                              ; preds = %179, %178
  %181 = load i32, ptr %8, align 4
  %182 = icmp slt i32 %181, 30
  br i1 %182, label %183, label %184

183:                                              ; preds = %180
  call void @mist_on()
  br label %185

184:                                              ; preds = %180
  call void @mist_off()
  br label %185

185:                                              ; preds = %184, %183
  %186 = load i32, ptr %9, align 4
  %187 = icmp slt i32 %186, 900
  br i1 %187, label %188, label %189

188:                                              ; preds = %185
  call void @vents_open()
  br label %190

189:                                              ; preds = %185
  call void @vents_close()
  br label %190

190:                                              ; preds = %189, %188
  %191 = load i32, ptr %11, align 4
  %192 = icmp slt i32 %191, 100
  br i1 %192, label %193, label %194

193:                                              ; preds = %190
  call void @grow_lights_on()
  br label %195

194:                                              ; preds = %190
  call void @grow_lights_off()
  br label %195

195:                                              ; preds = %194, %193
  %196 = load i32, ptr %6, align 4
  %197 = load i32, ptr %7, align 4
  %198 = load i32, ptr %8, align 4
  %199 = load i32, ptr %9, align 4
  %200 = load i32, ptr %10, align 4
  %201 = load i32, ptr %11, align 4
  call void @record_cycle(i32 noundef %196, i32 noundef %197, i32 noundef %198, i32 noundef %199, i32 noundef %200, i32 noundef %201)
  br label %202

202:                                              ; preds = %195
  %203 = load i32, ptr %6, align 4
  %204 = add nsw i32 %203, 1
  store i32 %204, ptr %6, align 4
  br label %18, !llvm.loop !6

205:                                              ; preds = %18
  %206 = load i32, ptr %5, align 4
  ret i32 %206
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
