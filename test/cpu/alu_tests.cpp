#include "fixture.hpp"
#include "flags.hpp"

#include <gtest/gtest.h>

TEST_F(CpuTest, ADC_with_carry) {
  bus_emulator->load_file(0x7FF0, "test_adc_with_carry");
  run_to_end(120);
  EXPECT_EQ(driver->instance.accumulator_o, 60);
  EXPECT_TRUE(StatusFlags(driver->instance.status_o).carry);
}
