#define CATCH_CONFIG_MAIN
#include <catch.hpp>

#include "Vcpu.h"

TEST_CASE("Test CPU") {
    Vcpu instance;
    instance.clock_i = 1;
    instance.reset_i = 1;
    instance.eval();

    REQUIRE(instance.data_o == 0);

    instance.clock_i = 0;
    instance.eval();
    instance.clock_i = 1;
    instance.eval();

    REQUIRE(instance.data_o == 1);
}
