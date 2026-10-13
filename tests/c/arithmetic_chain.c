// Expected: err is removed because two temperatures sum to at most 170.
int sensor_read(const char *name);
void err(void);

// Exercises interval propagation through addition before comparison folding.
int arithmetic_chain(void) {
  int temperature = sensor_read("temp_sensor");
  int doubled = temperature + temperature;
  if (doubled > 200) {
    err();
    return 1;
  }
  return 0;
}
