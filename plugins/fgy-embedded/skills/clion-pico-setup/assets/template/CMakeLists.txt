cmake_minimum_required(VERSION 4.1)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# ----------------------------------------------------------------------------
# Compiler
# ----------------------------------------------------------------------------
# CLI builds: if CMake doesn't know which compiler to use yet, include the
# helper that selects arm-none-eabi-*. From CLion with the "Pico ARM"
# toolchain, CMAKE_C_COMPILER is already set and this block is skipped.
if(NOT DEFINED CMAKE_C_COMPILER)
    include(pico_compilers.cmake)
endif()

# ----------------------------------------------------------------------------
# Pico SDK path
# ----------------------------------------------------------------------------
# Priority:
#   1. -DPICO_SDK_PATH=/path/to/pico-sdk (or CMakePresets.json)
#   2. PICO_SDK_PATH environment variable
#   3. otherwise: clear error
if(DEFINED PICO_SDK_PATH AND NOT PICO_SDK_PATH STREQUAL "")
    # Already defined via -D or CMakeCache.txt
elseif(DEFINED ENV{PICO_SDK_PATH})
    set(PICO_SDK_PATH "$ENV{PICO_SDK_PATH}" CACHE PATH "Path to the Raspberry Pi Pico SDK" FORCE)
else()
    message(FATAL_ERROR
            "PICO_SDK_PATH is not set.\n"
            "Set it with -DPICO_SDK_PATH=/path/to/pico-sdk\n"
            "or export PICO_SDK_PATH in your environment.")
endif()

if(NOT EXISTS "${PICO_SDK_PATH}/external/pico_sdk_import.cmake")
    message(FATAL_ERROR "Invalid PICO_SDK_PATH='${PICO_SDK_PATH}' (missing external/pico_sdk_import.cmake)")
endif()

message(STATUS "Using PICO_SDK_PATH=${PICO_SDK_PATH}")

# ----------------------------------------------------------------------------
# Board, SDK & project
# ----------------------------------------------------------------------------
# PICO_BOARD must be set before the SDK is imported: the SDK reads it while
# configuring board-specific settings. Override with -DPICO_BOARD=pico|pico_w.
set(PICO_BOARD "@BOARD@" CACHE STRING "Target Pico board (pico, pico_w)")

# Import the SDK before project() so its cross-compilation setup participates
# in compiler initialization.
include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(@PROJECT@ C CXX ASM)

# pico_sdk_init() must come after project().
pico_sdk_init()

# ----------------------------------------------------------------------------
# Executable
# ----------------------------------------------------------------------------
add_executable(@PROJECT@
        src/main.c
)

target_link_libraries(@PROJECT@
        PRIVATE
        pico_stdlib
)

# Pico W: the on-board LED is driven by the CYW43 wireless chip.
if(PICO_CYW43_SUPPORTED)
    target_link_libraries(@PROJECT@
            PRIVATE
            pico_cyw43_arch_none)
endif()

target_include_directories(@PROJECT@ PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}/src
)

# stdio transport for printf (@STDIO_LABEL_EN@)
pico_enable_stdio_usb(@PROJECT@ @STDIO_USB@)
pico_enable_stdio_uart(@PROJECT@ @STDIO_UART@)

# Extra outputs (.bin, .hex, .uf2 when picotool is available).
# SWD flashing through the Debug Probe only needs the .elf.
pico_add_extra_outputs(@PROJECT@)
