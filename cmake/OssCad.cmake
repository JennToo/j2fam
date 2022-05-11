set(FETCHCONTENT_QUIET FALSE)

FetchContent_Declare(
    osscadsuite
    URL https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2022-04-23/oss-cad-suite-linux-x64-20220423.tgz
    URL_HASH SHA256=9089c755dfbcff6a08e5878f1add6e658c08727fadb8d6fc6aa117895916ca17
)
FetchContent_MakeAvailable(osscadsuite)

set(osscad_WRAPPER ${CMAKE_BINARY_DIR}/oss-cad-wrapper)
configure_file(scripts/oss-cad-cmd.sh ${osscad_WRAPPER})
