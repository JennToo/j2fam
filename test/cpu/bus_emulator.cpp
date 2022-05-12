#include "bus_emulator.hpp"

#include <filesystem>
#include <fstream>
#include <strings.h>

BusEmulator::BusEmulator()
    : test_completed(false), test_clock_ready_count(0),
      test_almost_completed(false) {
  bzero(memory, BUS_SIZE);
}

void BusEmulator::load_file(size_t start_address, const char *file_name) {
  uint8_t *cursor = &memory[start_address];
  size_t read_size = BUS_SIZE - start_address;

  std::filesystem::path full_file_path =
      std::filesystem::path(PAYLOADS_DIRECTORY) /
      std::filesystem::path(std::string(file_name) + std::string(".nes"));
  std::ifstream file(full_file_path);
  ASSERT_TRUE(file);
  ASSERT_TRUE(file.read((char *)cursor, read_size));
  uint8_t *end_of_test =
      (uint8_t *)memmem(memory, BUS_SIZE, "END OF TEST", strlen("END OF TEST"));
  ASSERT_TRUE(end_of_test);
  end_of_test_address = end_of_test - &memory[0];
}

void BusEmulator::on_cycle(Vcpu &instance, uint64_t global_tick_count) {
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
