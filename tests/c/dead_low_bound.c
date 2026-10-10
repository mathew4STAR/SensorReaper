// Expected: the call to err is removed because temp_sensor is never below -100.
int sensor_read(const char *name);
void err(void);

// Contains a branch whose condition is false for every valid temperature value.
int dead_low_bound(void) {
  int temperature = sensor_read("temp_sensor");
  if (temperature < -100) {
    err();
    return 1;
  }
  return 0;
}
