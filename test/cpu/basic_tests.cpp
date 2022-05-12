#include "fixture.hpp"

#include <gtest/gtest.h>

TEST_F(CpuTest, NOP) {
  bus_emulator->load_file(0x7FF0, "test_nop");
  run_to_end(120);
  EXPECT_EQ(bus_emulator->test_clock_ready_count, 2 + RESET_CYCLE_OVERHEAD);
}

TEST_F(CpuTest, LDA_imm) {
  bus_emulator->load_file(0x7FF0, "test_lda_imm");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.accumulator_o == 142);
  EXPECT_TRUE(((driver->instance.status_o >> 7) & 1) != 0);
}

TEST_F(CpuTest, LDA_zp) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_lda_zp");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.accumulator_o == 74);
}

TEST_F(CpuTest, LDA_abs) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_lda_abs");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 4 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.accumulator_o == 42);
}

TEST_F(CpuTest, LDA_zpx) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_lda_zpx");
  run_to_end(120);
  EXPECT_TRUE(driver->instance.accumulator_o == 74);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 4 + RESET_CYCLE_OVERHEAD);
}

TEST_F(CpuTest, LDA_idx) {
  bus_emulator->load_file(0x7FF0, "test_lda_idx");
  run_to_end(500);
  EXPECT_TRUE(driver->instance.accumulator_o == 42);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 3 + 2 + 3 + 2 + 6 + RESET_CYCLE_OVERHEAD);
}

TEST_F(CpuTest, LDX_imm) {
  bus_emulator->load_file(0x7FF0, "test_ldx_imm");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.index_x_o == 42);
}

TEST_F(CpuTest, LDX_zp) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_ldx_zp");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.index_x_o == 74);
}

TEST_F(CpuTest, LDY_imm) {
  bus_emulator->load_file(0x7FF0, "test_ldy_imm");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.index_y_o == 42);
}

TEST_F(CpuTest, LDY_zp) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_ldy_zp");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.index_y_o == 74);
}

TEST_F(CpuTest, ADC_imm) {
  bus_emulator->load_file(0x7FF0, "test_adc_imm");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.accumulator_o == 216);
}

TEST_F(CpuTest, SBC_imm) {
  bus_emulator->load_file(0x7FF0, "test_sbc_imm");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.accumulator_o == 68);
}

TEST_F(CpuTest, JMP_abs) {
  bus_emulator->load_file(0x7FF0, "test_jmp_abs");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
}

TEST_F(CpuTest, STA_zp) {
  bus_emulator->load_file(0x7FF0, "test_sta_zp");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 3 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(bus_emulator->memory[0x42] == 74);
}

TEST_F(CpuTest, TAX) {
  bus_emulator->load_file(0x7FF0, "test_tax");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.index_x_o == 42);
}

TEST_F(CpuTest, TAY) {
  bus_emulator->load_file(0x7FF0, "test_tay");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.index_y_o == 42);
}

TEST_F(CpuTest, TXA) {
  bus_emulator->load_file(0x7FF0, "test_txa");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.accumulator_o == 42);
}

TEST_F(CpuTest, TYA) {
  bus_emulator->load_file(0x7FF0, "test_tya");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.accumulator_o == 42);
}

TEST_F(CpuTest, TXS) {
  bus_emulator->load_file(0x7FF0, "test_txs");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.stack_pointer_o == 42);
}

TEST_F(CpuTest, TSX) {
  bus_emulator->load_file(0x7FF0, "test_tsx");
  run_to_end(120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + 2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver->instance.stack_pointer_o == 42);
}
