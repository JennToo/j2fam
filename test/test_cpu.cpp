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
  Verilated::traceEverOn(true);

  Driver<Vcpu> driver("build/tests/test_cpu/trace.vcd");

  driver.instance.reset_i = 1;
  driver.run_cycles(1);
  driver.instance.reset_i = 0;
  driver.run_cycles(1);

  ClockDividerInvariant invariant;

  REQUIRE(driver.instance.data_o == 1);
  invariant.check(driver.instance);

  driver.run_cycles(1);

  REQUIRE(driver.instance.data_o == 2);
  invariant.check(driver.instance);

  driver.run_cycles(12);
}
