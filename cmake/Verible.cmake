FetchContent_Declare(
    verible
    URL https://github.com/chipsalliance/verible/releases/download/v0.0-2135-gb534c1fe/verible-v0.0-2135-gb534c1fe-Ubuntu-20.04-focal-x86_64.tar.gz
    URL_HASH SHA256=3973e05cbcf0a17eeb3b0546f899aec9713144c61420d95228ab16188f6ee0be
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
