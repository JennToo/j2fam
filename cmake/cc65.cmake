ExternalProject_Add(cc65
    GIT_REPOSITORY https://github.com/cc65/cc65.git
    GIT_TAG 451acb3423d503fc37995cc2cb79bb259138863b
    BUILD_COMMAND ${MAKE_EXE}
    BUILD_IN_SOURCE true
    CONFIGURE_COMMAND ""
    INSTALL_COMMAND ""
    UPDATE_COMMAND ""
)
ExternalProject_Get_property(cc65 SOURCE_DIR)
set(cc65_CA65_BIN ${SOURCE_DIR}/bin/ca65)
set(cc65_LD65_BIN ${SOURCE_DIR}/bin/ld65)

function(add_cc65_executable TARGET)
    cmake_parse_arguments(CC65 "" "LINKER" "ASSEMBLY" ${ARGN})

    get_filename_component(DIRNAME ${TARGET} DIRECTORY)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${DIRNAME})

    # TODO: Handle multiple assembly files
    set(INTERMEDIATE_OBJ ${CMAKE_BINARY_DIR}/${TARGET}.o)

    add_custom_command(
        OUTPUT ${INTERMEDIATE_OBJ}
        COMMAND ${cc65_CA65_BIN} -g -o ${INTERMEDIATE_OBJ} ${CMAKE_SOURCE_DIR}/${CC65_ASSEMBLY}
        DEPENDS cc65 ${CMAKE_SOURCE_DIR}/${CC65_ASSEMBLY}
    )
    add_custom_command(
        OUTPUT ${CMAKE_BINARY_DIR}/${TARGET}
        COMMAND ${cc65_LD65_BIN} -C ${CMAKE_SOURCE_DIR}/${CC65_LINKER} -o ${CMAKE_BINARY_DIR}/${TARGET} ${INTERMEDIATE_OBJ}
        DEPENDS cc65 ${INTERMEDIATE_OBJ} ${CMAKE_SOURCE_DIR}/${CC65_LINKER}
    )
endfunction()
