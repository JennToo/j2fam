#include "Vcpu.h"
#include "verilator_drivers.hpp"

#include <gtest/gtest.h>

#include <cstddef>
#include <ctime>
#include <fstream>
#include <sstream>
#include <stdint.h>
#include <strings.h>

const unsigned CLOCK_RATIO_DEFAULT = 12;
const unsigned RESET_CYCLE_OVERHEAD = 2 + 1;

struct ClockDividerInvariant : Driver<Vcpu>::Invariant {
  uint64_t last_clock_ready = 0;

  virtual void check(const Vcpu &instance,
                     uint64_t global_tick_count) override {
    if (instance.reset_i == 1) {
      last_clock_ready = global_tick_count;
    } else {
      if (global_tick_count - last_clock_ready == CLOCK_RATIO_DEFAULT) {
        EXPECT_TRUE(instance.clock_ready_o == 1);
        last_clock_ready = global_tick_count;
      } else {
        EXPECT_TRUE(instance.clock_ready_o == 0);
      }
    }
  }
};

const size_t BUS_SIZE = (1 << 16) - 1;

struct BusEmulator : Driver<Vcpu>::Listener {
  uint8_t memory[BUS_SIZE];
  size_t end_of_test_address;

  bool test_almost_completed;
  bool test_completed;
  uint64_t test_clock_ready_count;

  BusEmulator()
      : test_completed(false), test_clock_ready_count(0),
        test_almost_completed(false) {
    bzero(memory, BUS_SIZE);
  }

  void load_file(size_t start_address, const char *file_name) {
    uint8_t *cursor = &memory[start_address];
    size_t read_size = BUS_SIZE - start_address;
    std::ostringstream full_file_name;
    full_file_name << "build/cmake/test/payloads/" << file_name << ".nes";
    std::ifstream file(full_file_name.str());
    ASSERT_TRUE(file);
    ASSERT_TRUE(file.read((char *)cursor, read_size));
    uint8_t *end_of_test = (uint8_t *)memmem(memory, BUS_SIZE, "END OF TEST",
                                             strlen("END OF TEST"));
    ASSERT_TRUE(end_of_test);
    end_of_test_address = end_of_test - &memory[0];
  }

  virtual void on_cycle(Vcpu &instance, uint64_t global_tick_count) override {
    if (test_completed) {
      instance.data_valid_i = 0;
      return;
    }
    if (test_almost_completed && instance.clock_ready_o) {
      test_completed = true;
    }

    if (instance.clock_ready_o) {
      test_clock_ready_count++;
    }

    if (instance.bus_read_o == 1 || instance.bus_write_o) {
      if (instance.address_o < (BUS_SIZE - strlen("TEST FAILED"))) {
        EXPECT_TRUE(memcmp(&memory[instance.address_o], "TEST FAILED",
                           strlen("TEST FAILED")) != 0);
      }
      if (instance.address_o == end_of_test_address) {
        test_almost_completed = true;
        instance.data_valid_i = 0;
      } else if (instance.bus_write_o == 1) {
        memory[instance.address_o] = instance.data_o;
        instance.data_valid_i = 0;
      } else {
        instance.data_i = memory[instance.address_o];
        instance.data_valid_i = 1;
      }
    }
  }
};

void run_to_end(Driver<Vcpu> &driver, std::shared_ptr<BusEmulator> bus_emulator,
                size_t max_cycles) {
  while (max_cycles > 0 && !bus_emulator->test_completed) {
    max_cycles -= CLOCK_RATIO_DEFAULT;
    driver.run_cycles(12);
  }
  driver.run_cycles(12);
  EXPECT_TRUE(bus_emulator->test_completed);
}

class CpuTest : public ::testing::Test {
protected:
  CpuTest() : driver("build/tests/test_cpu") {}

  void SetUp() override {
    Verilated::traceEverOn(true);
    driver.invariants.push_back(std::make_unique<ClockDividerInvariant>());
    bus_emulator = std::make_shared<BusEmulator>();
    driver.listeners.push_back(bus_emulator);

    driver.instance.reset_i = 1;
    driver.run_cycles(1);
    driver.instance.reset_i = 0;
  }

  Driver<Vcpu> driver;
  std::shared_ptr<BusEmulator> bus_emulator;
};

TEST_F(CpuTest, NOP) {
  bus_emulator->load_file(0x7FF0, "test_nop");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_EQ(bus_emulator->test_clock_ready_count, 2 + RESET_CYCLE_OVERHEAD);
}

TEST_F(CpuTest, LDA_imm) {
  bus_emulator->load_file(0x7FF0, "test_lda_imm");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.accumulator_o == 142);
  EXPECT_TRUE(((driver.instance.status_o >> 7) & 1) != 0);
}

TEST_F(CpuTest, LDA_zp) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_lda_zp");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.accumulator_o == 74);
}

TEST_F(CpuTest, LDA_abs) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_lda_abs");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 4 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.accumulator_o == 42);
}

TEST_F(CpuTest, LDA_zpx) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_lda_zpx");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(driver.instance.accumulator_o == 74);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 4 + RESET_CYCLE_OVERHEAD);
}

TEST_F(CpuTest, LDA_idx) {
  bus_emulator->load_file(0x7FF0, "test_lda_idx");
  run_to_end(driver, bus_emulator, 500);
  EXPECT_TRUE(driver.instance.accumulator_o == 42);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 3 + 2 + 3 + 2 + 6 + RESET_CYCLE_OVERHEAD);
}

TEST_F(CpuTest, LDX_imm) {
  bus_emulator->load_file(0x7FF0, "test_ldx_imm");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.index_x_o == 42);
}

TEST_F(CpuTest, LDX_zp) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_ldx_zp");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.index_x_o == 74);
}

TEST_F(CpuTest, LDY_imm) {
  bus_emulator->load_file(0x7FF0, "test_ldy_imm");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.index_y_o == 42);
}

TEST_F(CpuTest, LDY_zp) {
  bus_emulator->memory[0x42] = 74;
  bus_emulator->load_file(0x7FF0, "test_ldy_zp");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.index_y_o == 74);
}

TEST_F(CpuTest, ADC_imm) {
  bus_emulator->load_file(0x7FF0, "test_adc_imm");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.accumulator_o == 216);
}

TEST_F(CpuTest, SBC_imm) {
  bus_emulator->load_file(0x7FF0, "test_sbc_imm");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.accumulator_o == 68);
}

TEST_F(CpuTest, JMP_abs) {
  bus_emulator->load_file(0x7FF0, "test_jmp_abs");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
}

TEST_F(CpuTest, STA_zp) {
  bus_emulator->load_file(0x7FF0, "test_sta_zp");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 3 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(bus_emulator->memory[0x42] == 74);
}

TEST_F(CpuTest, TAX) {
  bus_emulator->load_file(0x7FF0, "test_tax");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.index_x_o == 42);
}

TEST_F(CpuTest, TAY) {
  bus_emulator->load_file(0x7FF0, "test_tay");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.index_y_o == 42);
}

TEST_F(CpuTest, TXA) {
  bus_emulator->load_file(0x7FF0, "test_txa");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.accumulator_o == 42);
}

TEST_F(CpuTest, TYA) {
  bus_emulator->load_file(0x7FF0, "test_tya");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.accumulator_o == 42);
}

TEST_F(CpuTest, TXS) {
  bus_emulator->load_file(0x7FF0, "test_txs");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.stack_pointer_o == 42);
}

TEST_F(CpuTest, TSX) {
  bus_emulator->load_file(0x7FF0, "test_tsx");
  run_to_end(driver, bus_emulator, 120);
  EXPECT_TRUE(bus_emulator->test_clock_ready_count ==
              2 + 2 + 2 + 2 + RESET_CYCLE_OVERHEAD);
  EXPECT_TRUE(driver.instance.stack_pointer_o == 42);
}
