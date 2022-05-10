cmake_minimum_required(VERSION 3.16)

project(j2fam)

find_package(verilator REQUIRED HINTS ${CMAKE_SOURCE_DIR}/build/oss-cad-suite/share/verilator)

add_executable(test_cpu ${CMAKE_SOURCE_DIR}/test/test_cpu.cpp ${CMAKE_SOURCE_DIR}/test/lib/catch_main.cpp)
target_include_directories(test_cpu PRIVATE ${CMAKE_SOURCE_DIR}/test/lib ${CMAKE_SOURCE_DIR}/build/)
verilate(test_cpu SOURCES src/cpu.sv TRACE VERILATOR_ARGS -DSIMULATION)
