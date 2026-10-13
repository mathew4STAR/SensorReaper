// Expected: both alarm paths remain because neither condition is provably fixed.
#include <limits.h>

int sensor_read(const char *name);
void alarm(void);

// Mixing a sensor range with an unconstrained parameter must yield an unknown range.
int mixed_with_parameter(int adjustment) {
  int temperature = sensor_read("temp_sensor");
  if (temperature + adjustment > 200) {
    alarm();
    return 1;
  }
  return 0;
}

// A possible signed overflow must make the arithmetic result unknown.
int possible_overflow(void) {
  int temperature = sensor_read("temp_sensor");
  int shifted = temperature + INT_MAX;
  if (shifted > 0) {
    alarm();
    return 1;
  }
  return 0;
}
