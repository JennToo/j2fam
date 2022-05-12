#pragma once

#include "Vcpu.h"
#include "verilator_drivers.hpp"

const size_t BUS_SIZE = (1 << 16) - 1;

struct BusEmulator : Driver<Vcpu>::Listener {
  uint8_t memory[BUS_SIZE];
  size_t end_of_test_address;

  bool test_almost_completed;
  bool test_completed;
  uint64_t test_clock_ready_count;

  BusEmulator();
  void load_file(size_t start_address, const char *file_name);
  void on_cycle(Vcpu &instance, uint64_t global_tick_count) override;
};
