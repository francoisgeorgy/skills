# CLion configuration

Menu labels match CLion 2026.2; they can differ in other releases.

## One-time machine setup

### Toolchain `Pico ARM`

Settings > Build, Execution, Deployment > Toolchains > `+` > System. Name it exactly **`Pico ARM`**: `CMakePresets.json` links its presets to this name through `vendor.jetbrains.com/clion.toolchain`.

| Field | Value |
| --- | --- |
| CMake | Bundled, or installed version >= 4.1 |
| Build tool | Ninja (bundled is fine) |
| C compiler | Leave as detected, or the absolute path to `arm-none-eabi-gcc` (e.g. `/opt/homebrew/bin/arm-none-eabi-gcc`) |
| C++ compiler | Leave as detected, or the absolute path to `arm-none-eabi-g++` |
| Debugger | Leave as is: the toolchain Debugger field is deprecated since 2026.2; the run configuration selects GDB itself |

The `cc` / `c++` that CLion shows as detected is not used for the build. With the compiler fields left as detected, CLion passes no compiler to CMake: the project's `pico_compilers.cmake` and the Pico SDK toolchain file select `arm-none-eabi-gcc` / `arm-none-eabi-g++`. Explicit paths are optional; if set, they must point to `arm-none-eabi-*`, because a compiler passed by CLion takes precedence over both.

In every case the SDK searches `arm-none-eabi-gcc`, `-g++`, `-objcopy` and `-objdump` in the PATH CLion sees (or in `PICO_TOOLCHAIN_PATH`). If CMake stops with `Compiler 'arm-none-eabi-gcc' not found`, CLion does not see `/opt/homebrew/bin`: launch it from a terminal, or set `PICO_TOOLCHAIN_PATH` to the toolchain prefix (the directory that contains `bin/`) in a `CMakeUserPresets.json` (see below).

### OpenOCD executable

Settings > Build, Execution, Deployment > Embedded Development > OpenOCD location: path from `command -v openocd`. Keep the executable and its scripts from the same installation.

### `PICO_SDK_PATH` in CLion

The presets read `$env{PICO_SDK_PATH}`. An IDE started from the Dock may not see variables exported in the shell. If the CMake output says `PICO_SDK_PATH is not set`, either launch CLion from a terminal where it is exported, or create a `CMakeUserPresets.json` (already gitignored) next to `CMakePresets.json`:

```json
{
  "version": 6,
  "configurePresets": [
    { "name": "local-pico-w", "displayName": "local-pico-w", "inherits": "debug-pico-w",
      "cacheVariables": { "PICO_SDK_PATH": "/absolute/path/to/pico-sdk" } }
  ]
}
```

If using such a user preset, also change the run configuration's CMake profile to it.

### Optional: import configure presets only

Settings > Advanced Settings > *Automatically import CMake Presets*: choose configure presets only. Otherwise CLion also imports the build presets and shows duplicate `X - X preset` profiles.

## Per project

1. Open the directory **with CLion** (File > Open, or `open -a CLion .`), not with another JetBrains IDE. CLion loads the presets as read-only CMake profiles, shown as `<preset> preset` in the UI. The internal profile name (stored in `.idea/workspace.xml` and in `CONFIG_NAME` of `.run/*.run.xml`) is the bare preset name, e.g. `debug-pico-w`; verified with CLion 2026.2.3.
2. Settings > Build, Execution, Deployment > CMake: **enable** only `debug-pico preset` or `debug-pico-w preset` (imported presets are disabled by default). Disable the auto-created `Debug` profile.
3. Run > Edit Configurations: delete the auto-created *CMake Application* entries (`<name>`, `bs2_default*`, `*_pio_h`...). They are SDK or firmware targets that cannot run on the Mac.
4. Check the CMake output: Arm GCC compiler, expected SDK path and board.
5. Run configuration: select **`<name> SWD`** (OpenOCD Download & Run), loaded from `.run/`. It builds the target, downloads the ELF if changed, resets with `init` and uses GDB port 3333 / telnet 4444.
   - If the configuration shows no target or profile, reselect the target `<name>` and the enabled profile, then check *Executable binary* is the `.elf`.
6. **Run** flashes and runs. **Debug**: set a breakpoint in `main()`, check it is hit, then step and inspect a variable.
7. If the firmware was flashed by another tool, set Download to *Always* once.

Stop a debug session before starting another OpenOCD instance (CLion or CLI): two servers cannot share the probe.
