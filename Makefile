.DEFAULT_GOAL := help

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SOFTWARE_DIR := $(ROOT_DIR)/software
SIM_DIR := $(ROOT_DIR)/simulation
TOOLCHAIN_FILE := $(SOFTWARE_DIR)/riscv32.cmake

ifneq ($(wildcard /home/daniel/riscv/bin/riscv64-unknown-elf-gcc),)
DEFAULT_CROSS_COMPILE := /home/daniel/riscv/bin/riscv64-unknown-elf-
else
DEFAULT_CROSS_COMPILE := riscv64-unknown-elf-
endif

CMAKE ?= cmake
CROSS_COMPILE ?= $(DEFAULT_CROSS_COMPILE)
BUILD_DIR_NAME ?= build
SOFTWARE ?= smoketest

DIRECT_SOFTWARES := $(sort $(notdir $(patsubst %/,%,$(dir $(wildcard $(SOFTWARE_DIR)/*/CMakeLists.txt)))))
RECURSIVE_SOFTWARES := $(sort $(shell find "$(SOFTWARE_DIR)" -mindepth 2 -type f -name CMakeLists.txt -not -path '*/build/*' -printf '%h\n' | sed 's#^$(SOFTWARE_DIR)/##'))

SOFTWARE_BUILD_DIR = $(SOFTWARE_DIR)/$(1)/$(BUILD_DIR_NAME)
SOFTWARE_HEX = $(call SOFTWARE_BUILD_DIR,$(1))/$(notdir $(1)).hex

.PHONY: help list-software build-verilator build-software sim-run sim-software test smoke \
	test-all test-recursive clean-software clean-verilator clean $(DIRECT_SOFTWARES)

help:
	@echo "Hatch unified software + simulation flow"
	@echo
	@echo "Targets:"
	@echo "  make smoke                     Build and simulate smoketest"
	@echo "  make test SOFTWARE=<name>      Build and simulate one software app"
	@echo "  make <name>                    Alias for 'make test SOFTWARE=<name>'"
	@echo "  make test-all                  Run all top-level software apps"
	@echo "  make test-recursive            Run all software apps found recursively"
	@echo "  make build-software SOFTWARE=<name>"
	@echo "  make build-verilator"
	@echo "  make list-software"
	@echo
	@echo "Variables:"
	@echo "  SOFTWARE=$(SOFTWARE)"
	@echo "  CROSS_COMPILE=$(CROSS_COMPILE)"
	@echo
	@echo "Detected top-level software apps:"
	@printf "  %s\n" $(DIRECT_SOFTWARES)

list-software:
	@echo "Top-level software apps:"
	@printf "  %s\n" $(DIRECT_SOFTWARES)
	@echo
	@echo "Recursive software apps:"
	@printf "  %s\n" $(RECURSIVE_SOFTWARES)

build-verilator:
	@$(MAKE) -C "$(SIM_DIR)" build-verilator

build-software:
	@if [ ! -f "$(SOFTWARE_DIR)/$(SOFTWARE)/CMakeLists.txt" ]; then \
		echo "Unknown software: $(SOFTWARE)"; \
		echo "Use 'make list-software' to see valid options."; \
		exit 1; \
	fi
	@$(CMAKE) -S "$(SOFTWARE_DIR)/$(SOFTWARE)" -B "$(call SOFTWARE_BUILD_DIR,$(SOFTWARE))" \
		-DCMAKE_TOOLCHAIN_FILE="$(TOOLCHAIN_FILE)" \
		-DCROSS_COMPILE="$(CROSS_COMPILE)"
	@$(CMAKE) --build "$(call SOFTWARE_BUILD_DIR,$(SOFTWARE))"

sim-run: build-software
	@if [ ! -f "$(call SOFTWARE_HEX,$(SOFTWARE))" ]; then \
		echo "Missing HEX file: $(call SOFTWARE_HEX,$(SOFTWARE))"; \
		exit 1; \
	fi
	@$(MAKE) -C "$(SIM_DIR)" sim-verilator SW_HEX="$(call SOFTWARE_HEX,$(SOFTWARE))"

sim-software: build-verilator sim-run

test: sim-software

smoke:
	@$(MAKE) --no-print-directory test SOFTWARE=smoketest

test-all: build-verilator
	@set -e; \
	for app in $(DIRECT_SOFTWARES); do \
		echo "==== Testing $$app ===="; \
		$(MAKE) --no-print-directory sim-run SOFTWARE=$$app; \
	done

test-recursive: build-verilator
	@set -e; \
	for app in $(RECURSIVE_SOFTWARES); do \
		echo "==== Testing $$app ===="; \
		$(MAKE) --no-print-directory sim-run SOFTWARE=$$app; \
	done

clean-software:
	@if [ -d "$(SOFTWARE_DIR)/$(SOFTWARE)/$(BUILD_DIR_NAME)" ]; then \
		rm -rf "$(SOFTWARE_DIR)/$(SOFTWARE)/$(BUILD_DIR_NAME)"; \
	fi

clean-verilator:
	@$(MAKE) -C "$(SIM_DIR)" clean

clean: clean-software clean-verilator

$(DIRECT_SOFTWARES):
	@$(MAKE) --no-print-directory test SOFTWARE=$@
