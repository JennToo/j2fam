#pragma once

#include <cstdint>

struct StatusFlags {
  std::uint8_t raw;

  bool carry;

  inline StatusFlags(std::uint8_t raw) : raw(raw) { carry = (raw & 0b1) == 0; }
};
