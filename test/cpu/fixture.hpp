#pragma once

#include "bus_emulator.hpp"
#include "verilator_drivers.hpp"

#include "Vcpu.h"
#include <gtest/gtest.h>

#include <memory>

const unsigned CLOCK_RATIO_DEFAULT = 12;
const unsigned RESET_CYCLE_OVERHEAD = 2 + 1;

class CpuTest : public ::testing::Test {
protected:
  void SetUp() override;

  void run_to_end(size_t max_cycles);

  std::unique_ptr<Driver<Vcpu>> driver;
  std::shared_ptr<BusEmulator> bus_emulator;
};
