# Installing the prerequisites (macOS)

| Component | Install |
| --- | --- |
| Arm toolchain (gcc, g++, gdb, newlib) | `brew install --cask gcc-arm-embedded` |
| OpenOCD with RP2350 support | See [OpenOCD for RP2350](#openocd-for-rp2350) below, then rerun `check_prereqs.sh` to confirm `target/rp2350.cfg` |
| CMake >= 4.1 | `brew install cmake` or CLion's bundled CMake |
| Ninja | Optional: bundled with CLion, or `brew install ninja` |
| picotool | Optional, for `.uf2` output: `brew install picotool`. Without it, the SDK tries to fetch and build picotool, which needs network access |
| Git, Python 3, host compiler | `xcode-select --install` |

## Toolchain pitfall

Use the **cask** `gcc-arm-embedded` (Arm's prebuilt toolchain, includes `arm-none-eabi-gdb`). The Homebrew core formula `arm-none-eabi-gcc` builds GCC without target headers and without GDB: on its own it is not a complete Pico build/debug toolchain. The ARMmbed tap is deprecated and itself points to the cask.

## OpenOCD for RP2350

The OpenOCD 0.12.0 release predates RP2350 and has no `target/rp2350.cfg`. Homebrew's stable `openocd` is that release. Two sources provide the file, both with the Cortex-M33 cores as default target:

- Upstream master, through Homebrew's HEAD build (compiled locally; needs the Xcode command-line tools):

  ```sh
  brew uninstall --force open-ocd    # removes every installed version
  brew install --HEAD open-ocd
  ```

  Homebrew installs the build dependencies (autoconf, automake, libtool, texinfo, jimtcl). The executable path does not change, so CLion's OpenOCD location stays valid. Check with `ls "$(brew --prefix)/share/openocd/scripts/target/" | grep rp2`: both `rp2040.cfg` and `rp2350.cfg` must be listed.

  Update: plain `brew upgrade` skips HEAD installs. Use `brew upgrade --fetch-HEAD open-ocd`. Master is a development snapshot: after an update, flash a known project once (`openocd -f openocd-rp2350-cmsis-dap.cfg -c "program build/<board>/<name>.elf verify reset exit"`).

  Without `--force`, the HEAD build is added next to the 0.12.0 bottle, which stays linked: `openocd --version` still prints `0.12.0` and `rp2350.cfg` is still missing.

  Broken binary: the HEAD build links the Homebrew libraries present when it was compiled (jimtcl, capstone, hidapi, libftdi, libusb). When one of them moves to a new library version, OpenOCD stops starting with `dyld: Library not loaded: .../libjim.0.83.dylib` (or similar). Rebuild with the install commands above.

  Roll back: `brew uninstall --force open-ocd && brew install open-ocd` (loses RP2350 support).
- The Raspberry Pi fork, branch `sdk-2.0.0` (https://github.com/raspberrypi/openocd), built from source. Point CLion's OpenOCD location to that executable and keep its own `scripts` directory.

Either one still drives RP2040 targets, so `clion-pico-setup` projects keep working. Differences in master's `rp2040.cfg` compared with 0.12.0: both cores are debugged as one SMP target by default (core 1 shows as a second thread in CLion), and the flash driver `rp2040_flash` is renamed `rp2xxx` (only matters to scripts that name it).

## Pico SDK

```sh
mkdir -p ~/dev/pico
git clone https://github.com/raspberrypi/pico-sdk.git ~/dev/pico/pico-sdk
cd ~/dev/pico/pico-sdk
git checkout <release tag >= 2.0.0, e.g. 2.2.0>
git submodule update --init --recursive
echo 'export PICO_SDK_PATH="$HOME/dev/pico/pico-sdk"' >> ~/.zshrc
```

RP2350 (boards `pico2`, `pico2_w`) needs SDK 2.0.0 or later. Pick a release tag for reproducibility; the generated README records the SDK version found at creation time.

## References

- Raspberry Pi Debug Probe: https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html
- Pico SDK: https://github.com/raspberrypi/pico-sdk
- OpenOCD upstream: https://github.com/openocd-org/openocd (`tcl/target/rp2350.cfg`)
- Arm GNU toolchain: https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
