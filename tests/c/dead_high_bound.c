// Expected: err is removed because temp_sensor is never above 200.
int sensor_read(const char *name);
void err(void);

// Contains an upper-bound condition that is false for every valid temperature.
int dead_high_bound(void) {
  int temperature = sensor_read("temp_sensor");
  if (temperature > 200) {
    err();
    return 1;
  }
  return 0;
}
