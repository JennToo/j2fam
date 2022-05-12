FetchContent_Declare(
    verible
    URL https://github.com/chipsalliance/verible/releases/download/v0.0-2148-g0b02dd52/verible-v0.0-2148-g0b02dd52-Ubuntu-20.04-focal-x86_64.tar.gz
    URL_HASH SHA256=0ea734203cbbd6b258c213f9533cce30ca960c7f1889392d68484ac09d89c1e7
)
FetchContent_MakeAvailable(verible)

function(verible_check)
    cmake_parse_arguments(VERIBLE "" "RULESET" "SOURCES" ${ARGN})

    foreach(SOURCE ${VERIBLE_SOURCES})
        list(APPEND VERIBLE_CLEAN_SOURCES ${CMAKE_SOURCE_DIR}/${SOURCE})
    endforeach()
    add_custom_target(
        verible-lint
        ${verible_SOURCE_DIR}/bin/verible-verilog-lint --ruleset ${VERIBLE_RULESET} ${VERIBLE_CLEAN_SOURCES}
    )
    add_custom_target(
        verible-format
        ${verible_SOURCE_DIR}/bin/verible-verilog-format --inplace ${VERIBLE_CLEAN_SOURCES}
    )
endfunction()
