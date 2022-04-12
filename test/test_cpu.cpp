#include <catch.hpp>

#include "Vcpu.h"
#include "Vcpu___024root.h"
#include "verilator_drivers.hpp"

const unsigned CLOCK_RATIO_DEFAULT = 12;

struct ClockDividerInvariant {
  unsigned cycles_since_last_clock_ready = 0;

  void check(const Vcpu &instance) {
    if (cycles_since_last_clock_ready == CLOCK_RATIO_DEFAULT) {
      REQUIRE(instance.rootp->cpu__DOT__clock_ready == 1);
      cycles_since_last_clock_ready = 0;
    } else {
      REQUIRE(instance.rootp->cpu__DOT__clock_ready == 0);
      cycles_since_last_clock_ready++;
    }
  }
};

TEST_CASE("Test CPU") {
  Vcpu instance;
  instance.clock_i = 1;
  instance.reset_i = 1;
  instance.eval();

  ClockDividerInvariant invariant;

  REQUIRE(instance.data_o == 0);
  invariant.check(instance);

  run_cycles(instance, 1);

  REQUIRE(instance.data_o == 1);
  invariant.check(instance);
}
