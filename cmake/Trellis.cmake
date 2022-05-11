file(
    DOWNLOAD https://gist.githubusercontent.com/thoughtpolice/b1cec8d45f2741c3726c0cc2ac83d7f2/raw/6dd565cf7bfeee37f00720af008abb47a9405f45/ecp5pll.py
    ${CMAKE_BINARY_DIR}/ecp5pll.py
    EXPECTED_HASH SHA256=46c9854488dd73dd87e5e0502336a186e393ec891842a596c05164b1134300a2
)

function(add_trellis_bitstream TARGET)
    cmake_parse_arguments(TRELLIS "" "TOPLEVEL;LPF" "SOURCES;SYNTH_OPTIONS;PNR_OPTIONS" ${ARGN})

    set(TRELLIS_YOSYS_OUTPUT ${CMAKE_BINARY_DIR}/${TARGET}-yosys.json)
    set(TRELLIS_SCRIPT ${CMAKE_BINARY_DIR}/${TARGET}.ys)
    set(TRELLIS_PNR_OUTPUT ${CMAKE_BINARY_DIR}/${TARGET}.config)
    set(TRELLIS_PACK_OUTPUT ${CMAKE_BINARY_DIR}/${TARGET}.bit)

    foreach(SOURCE ${TRELLIS_SOURCES})
        set(TRELLIS_SOURCES_CLEAN "${TRELLIS_SOURCES_CLEAN} ${CMAKE_SOURCE_DIR}/${SOURCE}")
    endforeach()

    configure_file(scripts/synth.ys.in ${TRELLIS_SCRIPT})

    add_custom_command(
        OUTPUT ${TRELLIS_YOSYS_OUTPUT}
        COMMAND ${osscad_WRAPPER} yosys ${TRELLIS_SCRIPT}
        DEPENDS ${TRELLIS_SCRIPT} ${TRELLIS_SOURCES}
    )
    add_custom_command(
        OUTPUT ${TRELLIS_PNR_OUTPUT}
        COMMAND ${osscad_WRAPPER} nextpnr-ecp5 ${TRELLIS_PNR_OPTIONS} --json ${TRELLIS_YOSYS_OUTPUT}
        --lpf ${CMAKE_SOURCE_DIR}/${TRELLIS_LPF} --textcfg ${TRELLIS_PNR_OUTPUT}
        DEPENDS ${TRELLIS_LPF} ${TRELLIS_YOSYS_OUTPUT}
    )
    add_custom_command(
        OUTPUT ${TRELLIS_PACK_OUTPUT}
        COMMAND ${osscad_WRAPPER} ecppack ${TRELLIS_PNR_OUTPUT} ${TRELLIS_PACK_OUTPUT}
        DEPENDS ${TRELLIS_PNR_OUTPUT}
    )

    add_custom_target(${TARGET} ALL true DEPENDS ${TRELLIS_PACK_OUTPUT})
    add_custom_target(
        ${TARGET}-program ${osscad_WRAPPER} fujprog ${TRELLIS_PACK_OUTPUT}
        DEPENDS ${TRELLIS_PACK_OUTPUT}
    )
endfunction()
