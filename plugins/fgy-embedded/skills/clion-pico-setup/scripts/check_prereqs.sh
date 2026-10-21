#!/usr/bin/env bash
# Check the tools needed to build and debug a Pico project from CLion.
# Prints one line per check; exits 1 if a required item is missing.
set -uo pipefail

missing=0

check_tool() {
    local tool="$1" required="$2" path
    if path="$(command -v "$tool")"; then
        printf 'ok       %-20s %s (%s)\n' "$tool" "$path" "$("$tool" --version 2>&1 | head -n1)"
    elif [[ "$required" == 1 ]]; then
        printf 'MISSING  %s\n' "$tool"; missing=1
    else
        printf 'optional %-20s not on PATH\n' "$tool"
    fi
}

check_tool cmake 1
check_tool arm-none-eabi-gcc 1
check_tool arm-none-eabi-g++ 1
check_tool arm-none-eabi-gdb 1
check_tool openocd 1
check_tool git 1
check_tool python3 1
check_tool ninja 0      # CLion bundles its own Ninja
check_tool picotool 0   # only needed for .uf2 output

if command -v cmake >/dev/null; then
    v="$(cmake --version | head -n1 | awk '{print $3}')"
    if [[ "$(printf '%s\n4.1\n' "$v" | sort -V | head -n1)" != "4.1" ]]; then
        printf 'MISSING  cmake >= 4.1 (found %s)\n' "$v"; missing=1
    fi
fi

if [[ -z "${PICO_SDK_PATH:-}" ]]; then
    printf 'MISSING  PICO_SDK_PATH not set\n'; missing=1
elif [[ ! -f "$PICO_SDK_PATH/external/pico_sdk_import.cmake" ]]; then
    printf 'MISSING  PICO_SDK_PATH=%s is not a Pico SDK checkout\n' "$PICO_SDK_PATH"; missing=1
else
    printf 'ok       %-20s %s (%s)\n' PICO_SDK_PATH "$PICO_SDK_PATH" \
        "$(git -C "$PICO_SDK_PATH" describe --tags --always 2>/dev/null || echo 'version unknown')"
    if [[ ! -f "$PICO_SDK_PATH/lib/tinyusb/README.rst" ]]; then
        printf 'warning  SDK submodules look missing: git -C "%s" submodule update --init --recursive\n' "$PICO_SDK_PATH"
    fi
fi

if command -v openocd >/dev/null; then
    # Scripts normally live in <prefix>/share/openocd/scripts next to the executable.
    scripts="$(cd "$(dirname "$(command -v openocd)")/.." && pwd)/share/openocd/scripts"
    for cfg in interface/cmsis-dap.cfg target/rp2040.cfg; do
        if [[ -f "$scripts/$cfg" ]]; then
            printf 'ok       %-20s %s\n' "$cfg" "$scripts/$cfg"
        else
            printf 'warning  %s not found under %s (check the OpenOCD install)\n' "$cfg" "$scripts"
        fi
    done
fi

exit $missing
