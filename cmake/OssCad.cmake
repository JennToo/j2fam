set(FETCHCONTENT_QUIET FALSE)

FetchContent_Declare(
    osscadsuite
    URL https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2022-05-11/oss-cad-suite-linux-x64-20220511.tgz
    URL_HASH SHA256=0639f9965207ee8d7bc4b3ac59c20a2bae1146c6ea4d1a0ce77c8ad6ea4237f3
)
FetchContent_MakeAvailable(osscadsuite)

set(osscad_WRAPPER ${CMAKE_BINARY_DIR}/oss-cad-wrapper)
configure_file(scripts/oss-cad-cmd.sh ${osscad_WRAPPER})
