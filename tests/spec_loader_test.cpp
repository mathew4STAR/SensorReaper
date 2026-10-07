#include "SpecLoader.h"

#include <iostream>

// Prints every parsed sensor range and returns failure when loading fails.
int main(int argc, char **argv) {
  // Allow a custom file for testing, with the project specification as default.
  const std::string path = argc > 1 ? argv[1] : "spec/sensors.json";
  SpecLoader loader;
  std::string error;
  if (!loader.load(path, error)) {
    std::cerr << "Error: " << error << '\n';
    return 1;
  }

  // Print ranges in map order to make the test output deterministic.
  for (const auto &[name, limits] : loader.sensors())
    std::cout << name << ": [" << limits.min << ", " << limits.max << "]\n";
  return 0;
}
