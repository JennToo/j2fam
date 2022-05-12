cmake_minimum_required(VERSION 3.16)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED true)
set(FORMAT_SKIP_CMAKE true)
set(CMAKE_EXPORT_COMPILE_COMMANDS true)
set(CMAKE_CTEST_ARGUMENTS --output-on-failure)

enable_testing()

include(ExternalProject)
include(FetchContent)

include(OssCad)
include(cc65)
include(gtest)
include(Trellis)
include(Verible)

add_subdirectory(cmake/Format.cmake)

project(j2fam)

file(GLOB TEST_PAYLOADS RELATIVE ${CMAKE_SOURCE_DIR} test/payloads/*.s)
foreach(PAYLOAD ${TEST_PAYLOADS})
    string(REPLACE ".s" ".nes" PAYLOAD_BINARY ${PAYLOAD})
    add_cc65_executable(
        ${PAYLOAD_BINARY}
        ASSEMBLY ${PAYLOAD}
        LINKER test/payloads/linker_script.cfg
    )
    list(APPEND PAYLOAD_BINARIES ${PAYLOAD_BINARY})
endforeach()
add_custom_target(test-payloads ALL true DEPENDS ${PAYLOAD_BINARIES})

find_package(verilator REQUIRED HINTS ${osscadsuite_SOURCE_DIR}/share/verilator)

include(GoogleTest)
add_executable(test_cpu
    test/cpu/bus_emulator.cpp
    test/cpu/fixture.hpp
    test/cpu/basic_tests.cpp
    test/cpu/alu_tests.cpp
    test/cpu/fixture.cpp
    test/cpu/bus_emulator.hpp
)
target_link_libraries(test_cpu PRIVATE gtest_main)
target_include_directories(test_cpu PRIVATE ${CMAKE_SOURCE_DIR}/test/lib)
target_compile_definitions(
    test_cpu PRIVATE
    PAYLOADS_DIRECTORY="${CMAKE_BINARY_DIR}/test/payloads"
    VCD_TRACE_OUTPUT="${CMAKE_BINARY_DIR}/vcds/"
)
verilate(test_cpu SOURCES src/cpu.sv TRACE VERILATOR_ARGS -DSIMULATION)
add_dependencies(test_cpu test-payloads)
gtest_discover_tests(test_cpu)

add_trellis_bitstream(
    ulx3s-bitstream
    TOPLEVEL toplevel
    SOURCES boards/ulx3s/toplevel.sv src/cpu.sv
    SYNTH_OPTIONS -noccu2 -nomux -nodram
    LPF boards/ulx3s/ulx3s_v20.lpf
    PNR_OPTIONS --85k --package CABGA381
)

verible_check(
    RULESET all
    SOURCES boards/ulx3s/toplevel.sv src/cpu.sv
)
