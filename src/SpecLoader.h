#ifndef SENSOR_RANGE_SPEC_LOADER_H
#define SENSOR_RANGE_SPEC_LOADER_H

#include <cstdint>
#include <map>
#include <optional>
#include <string>

// Stores the integer limits declared for one named sensor.
struct SensorLimits {
  int64_t min;
  int64_t max;
  std::optional<int64_t> maxDeltaPerSample;
};

// Reads the project's deliberately flat sensor-specification JSON format.
class SpecLoader {
public:
  // Loads and validates every sensor entry in the file at path.
  bool load(const std::string &path, std::string &error);

  // Returns limits for name, or std::nullopt when the sensor is not listed.
  std::optional<SensorLimits> find(const std::string &name) const;

  // Returns all parsed limits so tests and the pass can inspect them.
  const std::map<std::string, SensorLimits> &sensors() const;

private:
  std::map<std::string, SensorLimits> m_sensors;
};

#endif
