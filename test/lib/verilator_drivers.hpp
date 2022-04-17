#pragma once

#include "verilated_vcd_c.h"

#include <bits/stdint-uintn.h>
#include <memory>
#include <sstream>
#include <stdint.h>
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

  Driver(const char *vcd_dest) {
    static unsigned vcd_counter = 0;
    std::ostringstream oss;
    oss << vcd_dest << "trace_" << vcd_counter << ".vcd";
    vcd_counter++;

    instance.trace(&traces, 2);
    traces.open(oss.str().c_str());

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
