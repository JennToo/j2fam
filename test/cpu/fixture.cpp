#include "fixture.hpp"

struct ClockDividerInvariant : Driver<Vcpu>::Invariant {
  uint64_t last_clock_ready = 0;

  virtual void check(const Vcpu &instance,
                     uint64_t global_tick_count) override {
    if (instance.reset_i == 1) {
      last_clock_ready = global_tick_count;
    } else {
      if (global_tick_count - last_clock_ready == CLOCK_RATIO_DEFAULT) {
        EXPECT_TRUE(instance.clock_ready_o == 1);
        last_clock_ready = global_tick_count;
      } else {
        EXPECT_TRUE(instance.clock_ready_o == 0);
      }
    }
  }
};

void CpuTest::SetUp() {
  Verilated::traceEverOn(true);
  driver = std::make_unique<Driver<Vcpu>>("cpu");
  driver->invariants.push_back(std::make_unique<ClockDividerInvariant>());
  bus_emulator = std::make_shared<BusEmulator>();
  driver->listeners.push_back(bus_emulator);

  driver->instance.reset_i = 1;
  driver->run_cycles(1);
  driver->instance.reset_i = 0;
}

void CpuTest::run_to_end(size_t max_cycles) {
  while (max_cycles > 0 && !bus_emulator->test_completed) {
    max_cycles -= CLOCK_RATIO_DEFAULT;
    driver->run_cycles(12);
  }
  driver->run_cycles(12);
  EXPECT_TRUE(bus_emulator->test_completed);
}
