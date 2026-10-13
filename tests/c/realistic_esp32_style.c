// Expected: six impossible err paths are removed; ordinary control paths remain.
int sensor_read(const char *name);
void err(void);
void alarm(void);
void fan_on(void);
void fan_off(void);
void dehumidifier_on(void);
void dehumidifier_off(void);
void vent_on(void);
void vent_off(void);
void dim_lights(void);
void brighten_lights(void);
void publish_environment(int temperature, int humidity, int pressure,
                         int distance, int light);

// Models a loop-free embedded environment-control cycle on an ESP32-style board.
int run_environment_controller(int manual_fan_request) {
  // Read the available environmental sensors once for this control cycle.
  int temperature = sensor_read("temp_sensor");
  int humidity = sensor_read("humidity_sensor");
  int pressure = sensor_read("pressure_sensor");
  int distance = sensor_read("distance_sensor");
  int light = sensor_read("light_sensor");

  // These six checks are physically impossible under the configured sensor spec.
  if (temperature < -100) {
    err();
    return -1;
  }
  if (temperature > 200) {
    err();
    return -2;
  }
  if (humidity > 120) {
    err();
    return -3;
  }
  if (pressure < 250) {
    err();
    return -4;
  }
  if (distance < 1) {
    err();
    return -5;
  }
  if (light == 0) {
    err();
    return -6;
  }

  // This high-temperature condition is possible, so its control path must remain.
  if (temperature > 50 || manual_fan_request) {
    fan_on();
    alarm();
  } else {
    fan_off();
  }

  // Both humidity outcomes are possible within the documented [0, 100] range.
  if (humidity >= 75)
    dehumidifier_on();
  else
    dehumidifier_off();

  // Both pressure outcomes are possible within the documented [300, 1100] range.
  if (pressure < 900)
    vent_on();
  else
    vent_off();

  // Both light outcomes are possible within the documented [1, 65535] range.
  if (light < 100)
    brighten_lights();
  else
    dim_lights();

  // Retain the readings as observable values after the optimization pipeline.
  publish_environment(temperature, humidity, pressure, distance, light);
  return 0;
}
