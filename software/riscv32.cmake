if(NOT DEFINED CROSS_COMPILE)
    set(CROSS_COMPILE "riscv64-unknown-elf-")
endif()

set(CMAKE_SYSTEM_NAME Generic-ELF)
set(CMAKE_SYSTEM_PROCESSOR riscv32)

set(CMAKE_ASM_COMPILER ${CROSS_COMPILE}gcc )
set(CMAKE_AR ${CROSS_COMPILE}ar)
set(CMAKE_ASM_COMPILER ${CROSS_COMPILE}gcc)
set(CMAKE_C_COMPILER ${CROSS_COMPILE}gcc)
set(CMAKE_CXX_COMPILER ${CROSS_COMPILE}g++)

set(RISCV_MARCH "rv32i_zicsr")
set(RISCV_MABI "ilp32")

set(RISCV_FLAGS "-march=${RISCV_MARCH} -mabi=${RISCV_MABI} -mcmodel=medany -static -std=gnu99 -Os -nostdlib -fno-builtin -ffreestanding")
set(CMAKE_C_FLAGS "${RISCV_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "-static -nostartfiles -lgcc ${RISCV_FLAGS}")

SET(ASM_OPTIONS "-x assembler-with-cpp")
SET(CMAKE_ASM_FLAGS "${RISCV_FLAGS} ${ASM_OPTIONS}" )

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# search headers and libraries in the target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)
