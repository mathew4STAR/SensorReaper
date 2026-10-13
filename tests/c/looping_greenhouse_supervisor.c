// Expected: 22 impossible err paths are removed; loop and live control paths remain.
int sensor_read(const char *name);
void err(int code);
void alarm(void);
void fan_on(void);
void fan_off(void);
void mist_on(void);
void mist_off(void);
void vents_open(void);
void vents_close(void);
void grow_lights_on(void);
void grow_lights_off(void);
void record_cycle(int cycle, int temperature, int humidity, int pressure,
                  int distance, int light);

// Runs repeated greenhouse control cycles to exercise loop phi nodes and pruning.
int run_greenhouse_supervisor(int cycles, int manual_fan_request) {
  int error_count = 0;

  // The loop creates LLVM phi nodes for cycle and error_count after mem2reg.
  for (int cycle = 0; cycle < cycles; ++cycle) {
    // Read each sensor once during this individual greenhouse control cycle.
    int temperature = sensor_read("temp_sensor");
    int humidity = sensor_read("humidity_sensor");
    int pressure = sensor_read("pressure_sensor");
    int distance = sensor_read("distance_sensor");
    int light = sensor_read("light_sensor");

    // Direct range checks: all are impossible according to spec/sensors.json.
    if (temperature < -100) { err(1); ++error_count; }
    if (temperature > 200) { err(2); ++error_count; }
    if (humidity < 0) { err(3); ++error_count; }
    if (humidity > 100) { err(4); ++error_count; }
    if (pressure < 300) { err(5); ++error_count; }
    if (pressure > 1100) { err(6); ++error_count; }
    if (distance < 2) { err(7); ++error_count; }
    if (distance > 400) { err(8); ++error_count; }
    if (light < 1) { err(9); ++error_count; }
    if (light > 65535) { err(10); ++error_count; }

    // Derive more ranges using operations already supported by the pass.
    int doubled_temperature = temperature + temperature;
    int shifted_temperature = temperature - 10;
    int raised_humidity = humidity + 5;
    int adjusted_pressure = pressure - 50;
    int doubled_distance = distance * 2;
    int adjusted_light = light - 1;

    // Arithmetic checks: every boundary is also impossible after propagation.
    if (doubled_temperature > 170) { err(11); ++error_count; }
    if (doubled_temperature < -80) { err(12); ++error_count; }
    if (shifted_temperature > 75) { err(13); ++error_count; }
    if (shifted_temperature < -50) { err(14); ++error_count; }
    if (raised_humidity > 105) { err(15); ++error_count; }
    if (raised_humidity < 5) { err(16); ++error_count; }
    if (adjusted_pressure > 1050) { err(17); ++error_count; }
    if (adjusted_pressure < 250) { err(18); ++error_count; }
    if (doubled_distance > 800) { err(19); ++error_count; }
    if (doubled_distance < 4) { err(20); ++error_count; }
    if (adjusted_light > 65534) { err(21); ++error_count; }
    if (adjusted_light < 0) { err(22); ++error_count; }

    // These decisions are deliberately live because valid sensor values vary.
    if (temperature > 50 || manual_fan_request) {
      fan_on();
      alarm();
    } else {
      fan_off();
    }

    // Humidity [0, 100] can be below or above this threshold.
    if (humidity < 30)
      mist_on();
    else
      mist_off();

    // Pressure [300, 1100] can be on either side of this threshold.
    if (pressure < 900)
      vents_open();
    else
      vents_close();

    // Light [1, 65535] can be on either side of this threshold.
    if (light < 100)
      grow_lights_on();
    else
      grow_lights_off();

    // Preserve observable data use and retain the loop-carried error_count phi.
    record_cycle(cycle, temperature, humidity, pressure, distance, light);
  }

  return error_count;
}
