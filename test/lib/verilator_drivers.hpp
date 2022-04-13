#pragma once

#include <bits/stdint-uintn.h>
#include <stdint.h>

#include "verilated_vcd_c.h"

const uint64_t TIMESCALE = 100;

template <typename ModuleT> struct Driver {
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
    }
  }
};
