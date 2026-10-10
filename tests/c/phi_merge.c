// Each direct read has a range supplied by spec/sensors.json.
int sensor_read(const char *name);

// Merges humidity [0, 100] and temperature [-40, 85] into [-40, 100].
int select_environment_value(int prefer_humidity) {
  if (prefer_humidity)
    return sensor_read("humidity_sensor");
  return sensor_read("temp_sensor");
}
