---
name: clion-pico2-setup
description: Create a new C project for Raspberry Pi Pico 2 / Pico 2 W (RP2350, Arm Cortex-M33) using the Pico SDK, ready to build in CLion and to flash and debug over SWD with a Raspberry Pi Debug Probe and OpenOCD. Generates CMakeLists.txt, CMakePresets.json, the OpenOCD config, a CLion "OpenOCD Download & Run" configuration and a blink main.c, then verifies the build. Use when the user wants to start, scaffold or bootstrap a Pico 2/RP2350 project, or set up CLion for Pico 2 development.
---

# CLion Pico 2 project setup

Scaffolds a Pico SDK project from a tested template, builds it once from the CLI to prove the toolchain works, then walks the user through the CLion steps that cannot be stored in the project.

Scope: RP2350 boards `pico2` and `pico2_w`, built for the Arm cores (`PICO_PLATFORM=rp2350-arm-s`). For Pico / Pico W (RP2040), use the `clion-pico-setup` skill instead. RISC-V (`rp2350-riscv`) is not supported: it needs a RISC-V toolchain and a different GDB.

## 1. Gather parameters

Ask only for what the user has not already given:

| Parameter | Values | Default |
| --- | --- | --- |
| Project name | C identifier `[A-Za-z_][A-Za-z0-9_]*`; becomes the CMake project, target and directory name | none, required |
| Parent directory | Existing directory; the project goes in `<parent>/<name>` | current directory |
| Board | `pico2`, `pico2_w` | `pico2_w` |
| stdio for `printf` | `usb` (USB CDC), `uart` (UART0 on GP0/GP1, readable through the probe's U port), `none` | `usb` |

Suggest a snake_case name if the user gives one with dashes or spaces.

## 2. Check prerequisites

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/check_prereqs.sh"
```

Act on the exit status:

| Exit | Meaning | Action |
| --- | --- | --- |
| 0 | Everything present | Continue |
| 1 | A required build item is missing (`MISSING` lines) | Stop and help install it using [references/install.md](references/install.md) |
| 2 | Build tools OK, but OpenOCD has no `target/rp2350.cfg` (`NOFLASH` line) | Continue with steps 3 and 4. Tell the user now, and again in step 6, that flashing and debugging will not work until OpenOCD is upgraded, and point to the "OpenOCD for RP2350" section of [references/install.md](references/install.md). Do not install or replace OpenOCD without the user's agreement |

Two items are specific to RP2350: Pico SDK >= 2.0.0 (exit 1 if older), and an OpenOCD that provides `target/rp2350.cfg` (exit 2; the 0.12.0 release, which Homebrew installs by default, does not). The script checks the `openocd` on PATH; if CLion is set to another executable, that one must provide the file too. `optional` and `warning` lines are not blockers: CLion bundles Ninja, and picotool is only needed for `.uf2` output.

## 3. Generate the project

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/new_project.sh" --name <name> --dir <parent> --board <board> --stdio <stdio>
```

The script refuses to write into a non-empty directory; never work around that by deleting anything. It detects `arm-none-eabi-gdb` for the run configuration (override with `--gdb PATH`) and runs `git init` (skip with `--no-git`).

Generated files: see the table in the generated `README.md` (English) and `README.fr.md` (French). Both are filled from the parameters above (board, stdio, preset, SDK version at creation). Do not hand-edit the template output beyond what the user asks for; if the user later changes the board or stdio, update both READMEs together.

## 4. Verify the build

From the new project directory. The preset uses Ninja; if `ninja` is not on PATH, use CLion's bundled copy (`find ~/Applications/CLion.app /Applications/CLion.app -type f -name ninja 2>/dev/null`) by prepending its directory to PATH for the command, or fall back to the plain command:

```sh
cmake --preset debug-<board with - instead of _> && cmake --build --preset debug-<board ...>
# fallback without Ninja:
cmake -S . -B build/<board> -DPICO_BOARD=<board> -DCMAKE_BUILD_TYPE=Debug && cmake --build build/<board>
```

Success means `build/<board>/<name>.elf` exists and the CMake output shows `PICO_PLATFORM` is `rp2350-arm-s`. Report the actual result. On failure, consult [references/troubleshooting.md](references/troubleshooting.md) before changing anything.

The CLI build directory is the same one the CLion preset uses, so CLion will reuse it. If CLion later complains about a generator or compiler mismatch, delete `build/<board>` and reload.

## 5. Guide the CLion setup

Give the user the steps from [references/clion.md](references/clion.md) that apply:
- One-time machine setup (toolchain named exactly `Pico ARM`, OpenOCD executable with RP2350 support) only if they have not done it before. Ask if unsure. A `Pico ARM` toolchain created for RP2040 projects works unchanged: the SDK selects the Cortex-M33 flags.
- Per project: open the directory with CLion, enable only the `debug-<board> preset` CMake profile, delete the auto-created CMake Application configurations, select the `<name> SWD` run configuration.

Then point to the wiring summary in [references/hardware.md](references/hardware.md) before the first flash.

## 6. Finish

Summarize: project path, board, stdio, build result, OpenOCD RP2350 support status, and the remaining manual CLion steps. Do not claim the firmware was flashed or tested on hardware: this skill cannot verify that.
