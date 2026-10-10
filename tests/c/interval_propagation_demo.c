// These direct sensor reads let the pass begin interval propagation.
int sensor_read(const char *name);

// Exercises add, sub, and mul using temp_sensor in the range [-40, 85].
int transform_temperature(void) {
  int temperature = sensor_read("temp_sensor");
  int doubled = temperature + temperature;
  int adjusted = doubled - 10;
  return adjusted * 2;
}

// Exercises sign extension with the same signed temperature range.
long extend_temperature(void) {
  return sensor_read("temp_sensor");
}

// Exercises zero extension because humidity_sensor is non-negative: [0, 100].
unsigned long extend_humidity(void) {
  return (unsigned long)sensor_read("humidity_sensor");
}

// Exercises safe truncation because temp_sensor fits in a signed 16-bit value.
short narrow_temperature(void) {
  return (short)sensor_read("temp_sensor");
}
