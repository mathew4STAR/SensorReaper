// Expected: humidity multiplied by zero becomes constant zero after the read.
int sensor_read(const char *name);

// Creates a sensor-derived instruction whose interval is exactly [0, 0].
int folded_sensor_expression(void) {
  int humidity = sensor_read("humidity_sensor");
  return humidity * 0;
}
