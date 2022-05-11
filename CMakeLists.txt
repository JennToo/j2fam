cmake_minimum_required(VERSION 3.16)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
set(CMAKE_CXX_STANDARD 17)

include(ExternalProject)
include(FetchContent)

include(OssCad)
include(cc65)
include(gtest)
include(Trellis)

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

add_executable(test_cpu ${CMAKE_SOURCE_DIR}/test/test_cpu.cpp)
target_link_libraries(test_cpu PRIVATE gtest_main)
target_include_directories(test_cpu PRIVATE ${CMAKE_SOURCE_DIR}/test/lib)
verilate(test_cpu SOURCES src/cpu.sv TRACE VERILATOR_ARGS -DSIMULATION)

add_trellis_bitstream(
    ulx3s-bitstream
    TOPLEVEL toplevel
    SOURCES boards/ulx3s/toplevel.sv src/cpu.sv
    SYNTH_OPTIONS -noccu2 -nomux -nodram
    LPF boards/ulx3s/ulx3s_v20.lpf
    PNR_OPTIONS --85k --package CABGA381
)
