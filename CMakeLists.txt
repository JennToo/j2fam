cmake_minimum_required(VERSION 3.16)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

include(ExternalProject)
include(cc65)

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

find_package(verilator REQUIRED HINTS ${CMAKE_SOURCE_DIR}/build/oss-cad-suite/share/verilator)

add_executable(test_cpu ${CMAKE_SOURCE_DIR}/test/test_cpu.cpp ${CMAKE_SOURCE_DIR}/test/lib/catch_main.cpp)
target_include_directories(test_cpu PRIVATE ${CMAKE_SOURCE_DIR}/test/lib ${CMAKE_SOURCE_DIR}/build/)
verilate(test_cpu SOURCES src/cpu.sv TRACE VERILATOR_ARGS -DSIMULATION)
