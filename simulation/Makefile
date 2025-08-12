HATCH_TOP=$(PWD)/..

VERILATOR_ARGS = -Wno-fatal -Wno-style \
	-Wno-BLKANDNBLK -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-WIDTHCONCAT -Wno-ASCRANGE

VERILATOR_ARGS += --binary -j 0
VERILATOR_ARGS += --timing --autoflush --trace-fst --trace-threads 2 --trace-structs
VERILATOR_ARGS +=  --unroll-count 1 --unroll-stmts 1
VERILATOR_ARGS += --x-assign fast --x-initial fast
VERILATOR_CFLAGS += -O3 -march=native -mtune=native

build-verilator:
	HATCH_TOP=$(HATCH_TOP) verilator $(VERILATOR_ARGS) -O3 --top tb_hatch -f hatch.vlt

SW_HEX ?= sw/smoketest.hex

sim-verilator:
	obj_dir/Vtb_hatch +binary="$(realpath $(SW_HEX))"