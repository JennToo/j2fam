#pragma once

#include "verilated_vcd_c.h"

#include <gtest/gtest.h>

#include <filesystem>
#include <memory>
#include <stdint.h>
#include <string>
#include <vector>

const uint64_t TIMESCALE = 46560 / 2;

template <typename ModuleT> struct Driver {
  struct Invariant {
    inline virtual ~Invariant() {}
    virtual void check(const ModuleT &, uint64_t) = 0;
  };
  struct Listener {
    inline virtual ~Listener() {}
    virtual void on_cycle(ModuleT &, uint64_t) = 0;
  };

  std::vector<std::unique_ptr<Invariant>> invariants;
  std::vector<std::shared_ptr<Listener>> listeners;

  ModuleT instance;
  VerilatedVcdC traces;

  uint64_t global_tick_count = 0;

  Driver(const std::filesystem::path &vcd_directory) {
    std::filesystem::path trace_dir =
        std::filesystem::path(VCD_TRACE_OUTPUT) / vcd_directory;
    std::filesystem::create_directories(trace_dir);
    auto test_info = ::testing::UnitTest::GetInstance()->current_test_info();
    std::filesystem::path filename =
        std::string(test_info->test_suite_name()) + std::string("_") +
        std::string(test_info->name()) + std::string(".vcd");
    auto trace_path = trace_dir / filename;

    instance.trace(&traces, 2);
    traces.open(trace_path.string().c_str());

    instance.clock_i = 0;
    instance.eval();
    traces.dump(TIMESCALE * 2 * global_tick_count);
    global_tick_count++;
  }

  ~Driver() {
    instance.clock_i = 0;
    instance.eval();
    traces.dump(TIMESCALE * 2 * global_tick_count);

    traces.close();
  }

  void run_cycles(unsigned count = 1) {
    while (count-- > 0) {
      instance.clock_i = 0;
      instance.eval();
      traces.dump(TIMESCALE * 2 * global_tick_count);

      instance.clock_i = 1;
      instance.eval();
      traces.dump(TIMESCALE * (2 * global_tick_count + 1));
      global_tick_count++;
      check_invariants();
      notify_listeners();
    }
  }

  void check_invariants() {
    for (const auto &invariant : invariants) {
      invariant->check(instance, global_tick_count);
    }
  }

  void notify_listeners() {
    for (const auto &listener : listeners) {
      listener->on_cycle(instance, global_tick_count);
    }
  }
};
