#pragma once

template <typename ModuleT>
void run_cycles(ModuleT &instance, unsigned count = 1) {
  while (count-- > 0) {
    instance.clock_i = 0;
    instance.eval();
    instance.clock_i = 1;
    instance.eval();
  }
}
