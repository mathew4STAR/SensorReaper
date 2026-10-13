// Expected: alarm remains because 50 lies inside temp_sensor's range [-40, 85].
int sensor_read(const char *name);
void alarm(void);

// Contains a condition that is possible but not guaranteed for a valid reading.
int live_threshold(void) {
  int temperature = sensor_read("temp_sensor");
  if (temperature > 50) {
    alarm();
    return 1;
  }
  return 0;
}
