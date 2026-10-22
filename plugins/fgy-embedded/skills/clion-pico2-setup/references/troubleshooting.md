# Troubleshooting

| Symptom | Check |
| --- | --- |
| `PICO_SDK_PATH is not set` / `Invalid PICO_SDK_PATH` | Export it, or pass `-DPICO_SDK_PATH=...`; in CLion see `clion.md` (CMakeUserPresets.json). Path must be the SDK root containing `external/pico_sdk_import.cmake` |
| `Unable to find definition of board 'pico2'` | Pico SDK older than 2.0.0: check out a 2.x tag, then `git submodule update --init --recursive` |
| `PICO_PLATFORM` is `rp2040` or `rp2350-riscv` | A `PICO_PLATFORM` environment variable or a stale cache overrides the project: unset it, delete `build/<board>`, reconfigure |
| Build directory switched between RP2040 and RP2350 boards | Platform and compiler are fixed at first configure: delete `build/<board>` (or `cmake-build-*`) and reconfigure |
| Missing TinyUSB / cyw43 / lwIP headers | SDK submodules: `git -C "$PICO_SDK_PATH" submodule update --init --recursive` |
| Host Clang used, or wrong architecture | CLion profile not on the `Pico ARM` toolchain, or toolchain uses `cc`. Fix, then Tools > CMake > Reset Cache and Reload Project. `pico_compilers.cmake` is skipped when a compiler is already set |
| `_exit` / `_sbrk` undefined during compiler checks | Cross-compiler not set before `project()`; for CLI builds, pass `-DARM_GCC_PATH=<toolchain prefix containing bin/>` |
| `CMake Error: generator Ninja does not match` | Build directory created by another generator: delete `build/<board>` |
| picotool download or build fails during configure | picotool missing and no network: `brew install picotool`. The `.elf` alone is enough for SWD |
| Preset not visible in CLion | Settings > CMake: enable it (imported presets start disabled) |
| OpenOCD: `Can't find target/rp2350.cfg` | OpenOCD 0.12.0 release, or a HEAD build installed next to it without `--force` (0.12.0 still linked): see `install.md` |
| OpenOCD: `dyld: Library not loaded` | HEAD build linked against a library version Homebrew has since upgraded: rebuild it (`install.md`) |
| OpenOCD cannot find `.cfg` | Executable and scripts from different installs; `PICO_SDK_PATH` plays no role here |
| No CMSIS-DAP device | Probe USB cable (data, not charge-only), probe firmware, another OpenOCD running |
| Probe found, target not | Target power, common GND, SWCLK/SWDIO swapped, lower adapter speed |
| Breakpoints not hit | Debug profile, flashed image matches the ELF (set Download to *Always* once) |
| No USB CDC device (`--stdio usb`) | Pico's own USB cable connected to the Mac, firmware not halted at a breakpoint |
| Mac tries to execute the firmware | Wrong run configuration: use `<name> SWD`, not CMake Application |
