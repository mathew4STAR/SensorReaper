// Expected: the error path is removed because both sensor bounds always hold.
int sensor_read(const char *name);
void err(void);

// Checks the full documented range of temp_sensor: [-40, 85].
int redundant_validation(void) {
  int temperature = sensor_read("temp_sensor");
  if (temperature >= -40 && temperature <= 85)
    return 0;
  err();
  return 1;
}
