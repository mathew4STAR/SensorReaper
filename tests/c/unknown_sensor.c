// Expected: alarm remains because this sensor name is absent from the JSON spec.
int sensor_read(const char *name);
void alarm(void);

// An unknown sensor must receive no invented range information.
int unknown_sensor(void) {
  int reading = sensor_read("unlisted_sensor");
  if (reading > 50) {
    alarm();
    return 1;
  }
  return 0;
}
