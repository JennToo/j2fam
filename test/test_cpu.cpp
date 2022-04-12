#include <catch.hpp>

#include "Vcpu.h"
#include "verilator_drivers.hpp"

TEST_CASE("Test CPU") {
  Vcpu instance;
  instance.clock_i = 1;
  instance.reset_i = 1;
  instance.eval();

  REQUIRE(instance.data_o == 0);

  run_cycles(instance, 1);

  REQUIRE(instance.data_o == 1);
}
