SHELL := /bin/bash

OSS_CAD_BUNDLE_VERSION := 20220408
OSS_CAD_BUNDLE_RELEASE := 2022-04-08
OSS_CAD_BUNDLE_URL := https://github.com/YosysHQ/oss-cad-suite-build/releases/download/$(OSS_CAD_BUNDLE_RELEASE)/oss-cad-suite-linux-x64-$(OSS_CAD_BUNDLE_VERSION).tgz
OSS_CAD_INSTALL_META := build/meta/oss-cad-$(OSS_CAD_BUNDLE_VERSION)
OSS_CAD_INSTALL_ROOT := build/oss-cad-suite
OSS_CAD_CMD := . $(OSS_CAD_INSTALL_ROOT)/environment ;

VERIBLE_VERSION := v0.0-2135-gb534c1fe
VERIBLE_URL := https://github.com/chipsalliance/verible/releases/download/$(VERIBLE_VERSION)/verible-$(VERIBLE_VERSION)-Ubuntu-20.04-focal-x86_64.tar.gz
VERIBLE_INSTALL_META := build/meta/verible-$(VERIBLE_VERSION)
VERIBLE_INSTALL_ROOT := build/verible

SV_SOURCES := $(shell find boards -name '*.sv')

.PHONY: all
all: $(OSS_CAD_INSTALL_META) $(VERIBLE_INSTALL_META)

$(OSS_CAD_INSTALL_META): | build/meta $(OSS_CAD_INSTALL_ROOT)
	rm -rf $(OSS_CAD_INSTALL_ROOT)
	mkdir -p $(OSS_CAD_INSTALL_ROOT)
	curl -L --fail $(OSS_CAD_BUNDLE_URL) | tar -C $(OSS_CAD_INSTALL_ROOT) -xzf - --strip-components=1
	touch $@

$(VERIBLE_INSTALL_META): | build/meta $(VERIBLE_INSTALL_ROOT)
	rm -rf $(VERIBLE_INSTALL_ROOT)
	mkdir -p $(VERIBLE_INSTALL_ROOT)
	curl -L --fail $(VERIBLE_URL) | tar -C $(VERIBLE_INSTALL_ROOT) -xzf - --strip-components=1
	touch $@

build/meta $(OSS_CAD_INSTALL_ROOT) $(VERIBLE_INSTALL_ROOT) build/ulx3s:
	mkdir -p $@

.PHONY: check
check: $(VERIBLE_INSTALL_META) $(OSS_CAD_INSTALL_META)
	$(VERIBLE_INSTALL_ROOT)/bin/verible-verilog-lint --ruleset all $(SV_SOURCES)
	./scripts/verible-format-check.sh $(SV_SOURCES)

.PHONY: format
format: $(VERIBLE_INSTALL_META)
	$(VERIBLE_INSTALL_ROOT)/bin/verible-verilog-format --inplace $(SV_SOURCES)

build/ulx3s/yosys_output.json: $(SV_SOURCES) $(OSS_CAD_INSTALL_META) | build/ulx3s
	$(OSS_CAD_CMD) yosys boards/ulx3s/synth.ys

build/ulx3s/out.config: build/ulx3s/yosys_output.json
	$(OSS_CAD_CMD) nextpnr-ecp5 --85k --json $< \
		--lpf boards/ulx3s/ulx3s_v20.lpf \
		--package CABGA381 \
		--textcfg $@

build/ulx3s/stream.bit: build/ulx3s/out.config
	$(OSS_CAD_CMD) ecppack $< $@

.PHONY: ulx3s
ulx3s: build/ulx3s/stream.bit
	$(OSS_CAD_CMD) fujprog $<
