# @PROJECT@

@BOARD_NAME@ (`@BOARD@`, RP2040) firmware in C with the Pico SDK. Developed with CLion, flashed and debugged over SWD with a Raspberry Pi Debug Probe and OpenOCD.

- Board: `@BOARD@`
- stdio (`printf`): @STDIO_LABEL_EN@
- SDK at creation: @SDK_VERSION@ (`PICO_SDK_PATH`)

French version: [README.fr.md](README.fr.md).

## Files

| File | Purpose |
| --- | --- |
| `src/main.c` | Program: LED blink + `printf` |
| `CMakeLists.txt` | Resolves `PICO_SDK_PATH`, sets the board (default `@BOARD@`), imports the SDK, defines the `@PROJECT@` target and stdio |
| `pico_compilers.cmake` | Selects `arm-none-eabi-*` for command-line builds; skipped when CLion provides the compiler |
| `CMakePresets.json` | `debug-pico` / `debug-pico-w` presets: Ninja, Debug, `build/<board>` directory, CLion toolchain `Pico ARM` |
| `openocd-rp2040-cmsis-dap.cfg` | OpenOCD: CMSIS-DAP probe + RP2040 target, SWD at 5000 kHz |
| `.run/@PROJECT@ SWD.run.xml` | CLion *OpenOCD Download & Run* configuration (flash + debug) |
| `.gitignore`, `.aiignore` | Exclusions for git and AI tools (build, `.idea/`, `CMakeUserPresets.json`...) |
| `CMakeUserPresets.json` | Optional, local, not versioned: per-machine overrides (e.g. `PICO_SDK_PATH`) |

Generated, not versioned: `build/<board>/` (CLI and CLion presets, contains `@PROJECT@.elf` / `.uf2`), `cmake-build-*/` (non-preset CLion profiles), `.idea/` (local CLion settings).

## CMake presets

- **Configure preset**: generation (`cmake --preset`): generator, build directory, board, build type.
- **Build preset**: compilation (`cmake --build --preset`) of an existing configure preset. Here just a shortcut.

The project still builds without presets, but you must pass `-DCMAKE_BUILD_TYPE=Debug` (otherwise the SDK forces `Release`).

## Command-line build

```sh
cmake --preset @PRESET@
cmake --build --preset @PRESET@
```

Without Ninja: `cmake -S . -B build/@BOARD@ -DCMAKE_BUILD_TYPE=Debug && cmake --build build/@BOARD@`.

Flash without CLion (CLion debug session stopped):

```sh
openocd -f openocd-rp2040-cmsis-dap.cfg -c "program build/@BOARD@/@PROJECT@.elf verify reset exit"
```

## CLion

Once per machine:
1. Toolchain named exactly `Pico ARM` (Settings > Build, Execution, Deployment > Toolchains), C/C++ = absolute paths to `arm-none-eabi-gcc` / `arm-none-eabi-g++`.
2. OpenOCD executable (Settings > ... > Embedded Development).
3. Optional: Settings > Advanced Settings > *Automatically import CMake Presets*: import configure presets only (avoids duplicate `X - X preset` profiles).

Per project:
1. Open the directory **with CLion** (File > Open, or `open -a CLion .`), not with another JetBrains IDE.
2. Settings > Build, Execution, Deployment > CMake: enable **`@PRESET@ preset`** only; disable the auto-created `Debug` profile.
3. Run > Edit Configurations: delete the auto-created *CMake Application* entries (`@PROJECT@`, `bs2_default*`, `*_pio_h`...), SDK targets that cannot run on the Mac.
4. Launch **`@PROJECT@ SWD`**: Run flashes and runs, Debug for breakpoints.

## SWD wiring

Probe port **D**: `SC` (orange) -> `SWCLK`, `GND` (black) -> `GND`, `SD` (yellow) -> `SWDIO`.
The SWD cable does not power the Pico: power it through its own USB. 3.3 V signals only.
