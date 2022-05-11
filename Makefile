SHELL := /bin/bash

VERIBLE_VERSION := v0.0-2135-gb534c1fe
VERIBLE_URL := https://github.com/chipsalliance/verible/releases/download/$(VERIBLE_VERSION)/verible-$(VERIBLE_VERSION)-Ubuntu-20.04-focal-x86_64.tar.gz
VERIBLE_INSTALL_META := build/meta/verible-$(VERIBLE_VERSION)
VERIBLE_INSTALL_ROOT := build/verible

SV_SOURCES := $(shell find boards src -name '*.sv')
CPP_SOURCES := $(shell find test -name '*.cpp')
HPP_SOURCES := $(shell find test -name '*.hpp')
TEST_LIB_SOURCES := $(shell find test/lib -name '*.cpp')

ASSEMBLY_PAYLOAD_SOURCES := $(shell find test/payloads -name '*.s')

.PHONY: all
all:

$(VERIBLE_INSTALL_META): | build/meta $(VERIBLE_INSTALL_ROOT)
	rm -rf $(VERIBLE_INSTALL_ROOT)
	mkdir -p $(VERIBLE_INSTALL_ROOT)
	curl -L --fail $(VERIBLE_URL) | tar -C $(VERIBLE_INSTALL_ROOT) -xzf - --strip-components=1
	touch $@

build/meta $(OSS_CAD_INSTALL_ROOT) $(VERIBLE_INSTALL_ROOT) build/ulx3s build/payloads:
	mkdir -p $@

.PHONY: check
check: $(VERIBLE_INSTALL_META) $(OSS_CAD_INSTALL_META)
	$(VERIBLE_INSTALL_ROOT)/bin/verible-verilog-lint --ruleset all $(SV_SOURCES)
	./scripts/verible-format-check.sh $(SV_SOURCES)

.PHONY: format
format: $(VERIBLE_INSTALL_META)
	$(VERIBLE_INSTALL_ROOT)/bin/verible-verilog-format --inplace $(SV_SOURCES)

.PHONY: test
test: test-cpu

.PHONY: test-cpu
test-cpu: build/cmake/test_cpu
	build/cmake/test_cpu

build/cmake/test_cpu: build/cmake/Makefile test/test_cpu.cpp src/cpu.sv $(TEST_LIB_SOURCES) $(ASSEMBLY_PAYLOAD_SOURCES) CMakeLists.txt
	$(MAKE) -C build/cmake

build/cmake/Makefile:
	rm -rf build/cmake
	mkdir -p $(@D)
	cd $(@D) && cmake ../..
