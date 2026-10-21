# Installing the prerequisites (macOS)

| Component | Install |
| --- | --- |
| Arm toolchain (gcc, g++, gdb, newlib) | `brew install --cask gcc-arm-embedded` |
| OpenOCD with RP2040 support | `brew install openocd`, then rerun `check_prereqs.sh` to confirm `target/rp2040.cfg` |
| CMake >= 4.1 | `brew install cmake` or CLion's bundled CMake |
| Ninja | Optional: bundled with CLion, or `brew install ninja` |
| picotool | Optional, for `.uf2` output: `brew install picotool`. Without it, the SDK tries to fetch and build picotool, which needs network access |
| Git, Python 3, host compiler | `xcode-select --install` |

## Toolchain pitfall

Use the **cask** `gcc-arm-embedded` (Arm's prebuilt toolchain, includes `arm-none-eabi-gdb`). The Homebrew core formula `arm-none-eabi-gcc` builds GCC without target headers and without GDB: on its own it is not a complete Pico build/debug toolchain. The ARMmbed tap is deprecated and itself points to the cask.

## Pico SDK

```sh
mkdir -p ~/dev/pico
git clone https://github.com/raspberrypi/pico-sdk.git ~/dev/pico/pico-sdk
cd ~/dev/pico/pico-sdk
git checkout <release tag, e.g. 2.2.0>
git submodule update --init --recursive
echo 'export PICO_SDK_PATH="$HOME/dev/pico/pico-sdk"' >> ~/.zshrc
```

Pick a release tag for reproducibility; the generated README records the SDK version found at creation time.

## References

- Raspberry Pi Debug Probe: https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html
- Pico SDK: https://github.com/raspberrypi/pico-sdk
- Arm GNU toolchain: https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
