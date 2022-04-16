#include "Vcpu.h"
#include "verilator_drivers.hpp"

#include <catch.hpp>

#include <cstddef>
#include <stdint.h>
#include <strings.h>

const unsigned CLOCK_RATIO_DEFAULT = 12;

struct ClockDividerInvariant : Driver<Vcpu>::Invariant {
  uint64_t last_clock_ready = 0;

  virtual void check(const Vcpu &instance,
                     uint64_t global_tick_count) override {
    if (instance.reset_i == 1) {
      last_clock_ready = global_tick_count;
    } else {
      if (global_tick_count - last_clock_ready == CLOCK_RATIO_DEFAULT) {
        REQUIRE(instance.clock_ready_o == 1);
        last_clock_ready = global_tick_count;
      } else {
        REQUIRE(instance.clock_ready_o == 0);
      }
    }
  }
};

const size_t BUS_SIZE = (1 << 16) - 1;

struct BusEmulator : Driver<Vcpu>::Listener {
  uint8_t memory[BUS_SIZE];

  BusEmulator() { bzero(memory, BUS_SIZE); }

  virtual void on_cycle(Vcpu &instance, uint64_t global_tick_count) override {
    if (instance.address_valid_o == 1) {
      if (instance.data_valid_o == 1) {
        memory[instance.address_o] = instance.data_o;
      } else {
        instance.data_i = memory[instance.address_o];
        // TODO: We'll want to reset this after a while
        instance.data_valid_i = 1;
      }
    }
  }
};

TEST_CASE("Test CPU") {
  Verilated::traceEverOn(true);

  Driver<Vcpu> driver("build/tests/test_cpu/trace.vcd");
  driver.invariants.push_back(std::make_unique<ClockDividerInvariant>());
  auto bus_emulator = std::make_shared<BusEmulator>();
  driver.listeners.push_back(bus_emulator);

  bus_emulator->memory[0xFFFC] = 0x00;
  bus_emulator->memory[0xFFFD] = 0x40;

  driver.instance.reset_i = 1;
  driver.run_cycles(1);
  driver.instance.reset_i = 0;
  driver.run_cycles(120);
}
