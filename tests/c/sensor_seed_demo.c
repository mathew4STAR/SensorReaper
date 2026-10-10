// This direct sensor read should be seeded with the range [-40, 85].
int sensor_read(const char *name);

// Returns a temperature value so the call remains visible in LLVM IR.
int read_temperature(void) {
  return sensor_read("temp_sensor");
}
