# Troubleshooting

| Symptom | Check |
| --- | --- |
| `PICO_SDK_PATH is not set` / `Invalid PICO_SDK_PATH` | Export it, or pass `-DPICO_SDK_PATH=...`; in CLion see `clion.md` (CMakeUserPresets.json). Path must be the SDK root containing `external/pico_sdk_import.cmake` |
| Missing TinyUSB / cyw43 / lwIP headers | SDK submodules: `git -C "$PICO_SDK_PATH" submodule update --init --recursive` |
| Host Clang used, or wrong architecture | CLion profile not on the `Pico ARM` toolchain, or toolchain uses `cc`. Fix, then Tools > CMake > Reset Cache and Reload Project. `pico_compilers.cmake` is skipped when a compiler is already set |
| `_exit` / `_sbrk` undefined during compiler checks | Cross-compiler not set before `project()`; for CLI builds, pass `-DARM_GCC_PATH=<toolchain prefix containing bin/>` |
| `CMake Error: generator Ninja does not match` | Build directory created by another generator: delete `build/<board>` |
| picotool download or build fails during configure | picotool missing and no network: `brew install picotool`. The `.elf` alone is enough for SWD |
| Preset not visible in CLion | Settings > CMake: enable it (imported presets start disabled) |
| OpenOCD cannot find `.cfg` | Executable and scripts from different installs; `PICO_SDK_PATH` plays no role here |
| No CMSIS-DAP device | Probe USB cable (data, not charge-only), probe firmware, another OpenOCD running |
| Probe found, target not | Target power, common GND, SWCLK/SWDIO swapped, lower adapter speed |
| Breakpoints not hit | Debug profile, flashed image matches the ELF (set Download to *Always* once) |
| No USB CDC device (`--stdio usb`) | Pico's own USB cable connected to the Mac, firmware not halted at a breakpoint |
| Mac tries to execute the firmware | Wrong run configuration: use `<name> SWD`, not CMake Application |
