#include "Vcpu.h"
#include "Vcpu___024root.h"
#include "verilator_drivers.hpp"

#include <catch.hpp>

#include <stdint.h>

const unsigned CLOCK_RATIO_DEFAULT = 12;

struct ClockDividerInvariant : Driver<Vcpu>::Invariant {
  uint64_t last_clock_ready = 0;

  virtual void check(const Vcpu &instance,
                     uint64_t global_tick_count) override {
    if (instance.reset_i == 1) {
      last_clock_ready = global_tick_count;
    } else {
      if (global_tick_count - last_clock_ready == CLOCK_RATIO_DEFAULT) {
        REQUIRE(instance.rootp->cpu__DOT__clock_ready == 1);
        last_clock_ready = global_tick_count;
      } else {
        REQUIRE(instance.rootp->cpu__DOT__clock_ready == 0);
      }
    }
  }
};

TEST_CASE("Test CPU") {
  Verilated::traceEverOn(true);

  Driver<Vcpu> driver("build/tests/test_cpu/trace.vcd");
  driver.invariants.push_back(std::make_unique<ClockDividerInvariant>());

  driver.instance.reset_i = 1;
  driver.run_cycles(1);
  driver.instance.reset_i = 0;
  driver.run_cycles(1);

  REQUIRE(driver.instance.data_o == 1);

  driver.run_cycles(1);

  REQUIRE(driver.instance.data_o == 2);

  driver.run_cycles(120);
}
