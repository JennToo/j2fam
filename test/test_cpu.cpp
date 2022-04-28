#include "Vcpu.h"
#include "verilator_drivers.hpp"

#include <catch.hpp>

#include <cstddef>
#include <ctime>
#include <fstream>
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
        CHECK(instance.clock_ready_o == 1);
        last_clock_ready = global_tick_count;
      } else {
        CHECK(instance.clock_ready_o == 0);
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
    std::ifstream file(file_name);
    REQUIRE(file);
    REQUIRE(file.read((char *)cursor, read_size));
    uint8_t *end_of_test = (uint8_t *)memmem(memory, BUS_SIZE, "END OF TEST",
                                             strlen("END OF TEST"));
    REQUIRE(end_of_test);
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
        CHECK(memcmp(&memory[instance.address_o], "TEST FAILED",
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
  CHECK(bus_emulator->test_completed);
}

TEST_CASE("Test CPU minimal instructions") {
  Verilated::traceEverOn(true);

  Driver<Vcpu> driver("build/tests/test_cpu/");
  driver.invariants.push_back(std::make_unique<ClockDividerInvariant>());
  auto bus_emulator = std::make_shared<BusEmulator>();
  driver.listeners.push_back(bus_emulator);

  driver.instance.reset_i = 1;
  driver.run_cycles(1);
  driver.instance.reset_i = 0;

  SECTION("Check NOP") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_nop");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
  }
  SECTION("Check LDA immediate") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_lda_imm");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.accumulator_o == 142);
    CHECK(((driver.instance.status_o >> 7) & 1) != 0);
  }
  SECTION("Check LDA zeropage") {
    bus_emulator->memory[0x42] = 74;
    bus_emulator->load_file(0x7FF0, "build/payloads/test_lda_zp");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.accumulator_o == 74);
  }
  SECTION("Check LDA absolute") {
    bus_emulator->memory[0x42] = 74;
    bus_emulator->load_file(0x7FF0, "build/payloads/test_lda_abs");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 4 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.accumulator_o == 42);
  }
  SECTION("Check LDA zeropage,X") {
    bus_emulator->memory[0x42] = 74;
    bus_emulator->load_file(0x7FF0, "build/payloads/test_lda_zpx");
    run_to_end(driver, bus_emulator, 120);
    CHECK(driver.instance.accumulator_o == 74);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 4 + RESET_CYCLE_OVERHEAD);
  }
  SECTION("Check LDA indirect,X") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_lda_idx");
    run_to_end(driver, bus_emulator, 500);
    CHECK(driver.instance.accumulator_o == 42);
    CHECK(bus_emulator->test_clock_ready_count ==
          2 + 3 + 2 + 3 + 2 + 6 + RESET_CYCLE_OVERHEAD);
  }
  SECTION("Check LDX immediate") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_ldx_imm");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.index_x_o == 42);
  }
  SECTION("Check LDX zeropage") {
    bus_emulator->memory[0x42] = 74;
    bus_emulator->load_file(0x7FF0, "build/payloads/test_ldx_zp");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.index_x_o == 74);
  }
  SECTION("Check LDY immediate") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_ldy_imm");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.index_y_o == 42);
  }
  SECTION("Check LDY zeropage") {
    bus_emulator->memory[0x42] = 74;
    bus_emulator->load_file(0x7FF0, "build/payloads/test_ldy_zp");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.index_y_o == 74);
  }
  SECTION("Check ADC immediate") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_adc_imm");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.accumulator_o == 216);
  }
  SECTION("Check SBC immediate") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_sbc_imm");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.accumulator_o == 68);
  }
  SECTION("Check JMP absolute") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_jmp_abs");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 3 + RESET_CYCLE_OVERHEAD);
  }
  SECTION("Check STA zeropage") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_sta_zp");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 3 + RESET_CYCLE_OVERHEAD);
    CHECK(bus_emulator->memory[0x42] == 74);
  }
  SECTION("Check TAX") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_tax");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.index_x_o == 42);
  }
  SECTION("Check TAY") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_tay");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.index_y_o == 42);
  }
  SECTION("Check TXA") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_txa");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.accumulator_o == 42);
  }
  SECTION("Check TYA") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_tya");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.accumulator_o == 42);
  }
  SECTION("Check TXS") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_txs");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count == 2 + 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.stack_pointer_o == 42);
  }
  SECTION("Check TSX") {
    bus_emulator->load_file(0x7FF0, "build/payloads/test_tsx");
    run_to_end(driver, bus_emulator, 120);
    CHECK(bus_emulator->test_clock_ready_count ==
          2 + 2 + 2 + 2 + RESET_CYCLE_OVERHEAD);
    CHECK(driver.instance.stack_pointer_o == 42);
  }
}
