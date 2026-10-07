#include "SpecLoader.h"

#include <fstream>
#include <iterator>
#include <regex>

// Loads a flat JSON object whose entries contain integer min and max fields.
bool SpecLoader::load(const std::string &path, std::string &error) {
  std::ifstream input(path);
  if (!input) {
    error = "could not open sensor specification: " + path;
    return false;
  }

  // Read the small specification file into one string before matching entries.
  std::string text((std::istreambuf_iterator<char>(input)),
                   std::istreambuf_iterator<char>());
  // This expression accepts the documented field order and optional delta field.
  const std::regex entry(
      R"spec("([^"]+)"\s*:\s*\{\s*"min"\s*:\s*(-?[0-9]+)\s*,\s*"max"\s*:\s*(-?[0-9]+)(?:\s*,\s*"max_delta_per_sample"\s*:\s*(-?[0-9]+))?\s*\})spec");

  sensors_.clear();
  for (std::sregex_iterator it(text.begin(), text.end(), entry), end; it != end;
       ++it) {
    // Convert matched decimal text to signed 64-bit limits.
    const int64_t min = std::stoll((*it)[2].str());
    const int64_t max = std::stoll((*it)[3].str());
    if (min > max) {
      error = "minimum exceeds maximum for sensor: " + (*it)[1].str();
      sensors_.clear();
      return false;
    }

    // Store the optional sample-to-sample bound only when it was supplied.
    std::optional<int64_t> delta;
    if ((*it)[4].matched) {
      delta = std::stoll((*it)[4].str());
      if (*delta < 0) {
        error = "max_delta_per_sample must not be negative";
        sensors_.clear();
        return false;
      }
    }
    sensors_[(*it)[1].str()] = {min, max, delta};
  }

  if (sensors_.empty()) {
    error = "no valid sensor entries found in: " + path;
    return false;
  }
  return true;
}

// Looks up a sensor name without changing the loaded specification.
std::optional<SensorLimits> SpecLoader::find(const std::string &name) const {
  const auto found = sensors_.find(name);
  if (found == sensors_.end())
    return std::nullopt;
  return found->second;
}

// Exposes the parsed map for diagnostics and the standalone test.
const std::map<std::string, SensorLimits> &SpecLoader::sensors() const {
  return sensors_;
}
