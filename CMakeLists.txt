cmake_minimum_required(VERSION 3.13)

# Build an out-of-tree LLVM pass plugin using C++17.
project(SensorReaper LANGUAGES CXX)

# LLVM_DIR should name LLVM's installed CMake package directory.
find_package(LLVM REQUIRED CONFIG)

# Print the LLVM version and headers selected by CMake for troubleshooting.
message(STATUS "Using LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVM headers from ${LLVM_INCLUDE_DIRS}")

# Build the shared library that opt loads with -load-pass-plugin.
add_library(SensorReaperPass MODULE
  src/SensorRangePass.cpp
  src/SpecLoader.cpp)

# Let the pass source include LLVM's public C++ headers.
target_include_directories(SensorReaperPass PRIVATE ${LLVM_INCLUDE_DIRS})

# Match the language level required by the project.
target_compile_features(SensorReaperPass PRIVATE cxx_std_17)

# Link to LLVM's shared library, which provides the new-pass-manager API.
target_link_libraries(SensorReaperPass PRIVATE LLVM)

# Produce build/SensorReaperPass.so instead of libSensorRangePass.so.
set_target_properties(SensorReaperPass PROPERTIES
  PREFIX ""
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
