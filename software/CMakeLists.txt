# Add executable target

enable_language(C ASM)

set(SDK_DIR ${CMAKE_CURRENT_LIST_DIR}/sdk)

include_directories(${SDK_DIR}/include)
set(SOURCES ${SOURCES} ${SDK_DIR}/lib/print.c ${SDK_DIR}/lib/uart.c ${SDK_DIR}/lib/platform.c ${SDK_DIR}/lib/gpio.c ${SDK_DIR}/lib/timer.c ${SDK_DIR}/lib/crt0.S)

add_link_options("-T${SDK_DIR}/link.ld")

add_executable(${TARGET_NAME} ${SOURCES})

add_custom_command(
    TARGET ${TARGET_NAME}
    POST_BUILD
    COMMAND ${CROSS_COMPILE}objcopy -O verilog $<TARGET_FILE:${TARGET_NAME}> ${TARGET_NAME}.hex
    COMMENT "Generating Verilog hex file from ${TARGET_NAME}"
)

add_custom_command(
    TARGET ${TARGET_NAME}
    POST_BUILD
    COMMAND ${CROSS_COMPILE}objdump -d $<TARGET_FILE:${TARGET_NAME}> > ${TARGET_NAME}.dis
    COMMENT "Generating disassembly from ${TARGET_NAME}"
)