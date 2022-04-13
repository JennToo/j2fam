#pragma once

#include "verilated_vcd_c.h"

#include <bits/stdint-uintn.h>
#include <memory>
#include <stdint.h>
#include <vector>

const uint64_t TIMESCALE = 100;

template <typename ModuleT> struct Driver {
  struct Invariant {
    inline virtual ~Invariant() {}
    virtual void check(const ModuleT &, uint64_t) = 0;
  };

  std::vector<std::unique_ptr<Invariant>> invariants;

  ModuleT instance;
  VerilatedVcdC traces;

  uint64_t global_tick_count = 0;

  Driver(const char *vcd_dest) {
    instance.trace(&traces, 2);
    traces.open(vcd_dest);

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
    }
  }

  void check_invariants() {
    for (const auto &invariant : invariants) {
      invariant->check(instance, global_tick_count);
    }
  }
};
