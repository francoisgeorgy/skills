---
name: clion-pico-setup
description: Create a new C project for Raspberry Pi Pico / Pico W (RP2040) using the Pico SDK, ready to build in CLion and to flash and debug over SWD with a Raspberry Pi Debug Probe and OpenOCD. Generates CMakeLists.txt, CMakePresets.json, the OpenOCD config, a CLion "OpenOCD Download & Run" configuration and a blink main.c, then verifies the build. Use when the user wants to start, scaffold or bootstrap a Pico/RP2040 project, or set up CLion for Pico development.
---

# CLion Pico project setup

Scaffolds a Pico SDK project from a tested template, builds it once from the CLI to prove the toolchain works, then walks the user through the CLion steps that cannot be stored in the project.

Scope: RP2040 boards `pico` and `pico_w` only. For Pico 2 (RP2350), say it is not supported by this skill: it needs a different OpenOCD target and CPU settings.

## 1. Gather parameters

Ask only for what the user has not already given:

| Parameter | Values | Default |
| --- | --- | --- |
| Project name | C identifier `[A-Za-z_][A-Za-z0-9_]*`; becomes the CMake project, target and directory name | none, required |
| Parent directory | Existing directory; the project goes in `<parent>/<name>` | current directory |
| Board | `pico`, `pico_w` | `pico_w` |
| stdio for `printf` | `usb` (USB CDC), `uart` (UART0 on GP0/GP1, readable through the probe's U port), `none` | `usb` |

Suggest a snake_case name if the user gives one with dashes or spaces.

## 2. Check prerequisites

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/check_prereqs.sh"
```

Exit 1 means a required item is missing. Stop and help install it using [references/install.md](references/install.md). `optional` lines are not blockers: CLion bundles Ninja, and picotool is only needed for `.uf2` output.

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

Success means `build/<board>/<name>.elf` exists. Report the actual result. On failure, consult [references/troubleshooting.md](references/troubleshooting.md) before changing anything.

The CLI build directory is the same one the CLion preset uses, so CLion will reuse it. If CLion later complains about a generator or compiler mismatch, delete `build/<board>` and reload.

## 5. Guide the CLion setup

Give the user the steps from [references/clion.md](references/clion.md) that apply:
- One-time machine setup (toolchain named exactly `Pico ARM`, OpenOCD executable) only if they have not done it before. Ask if unsure.
- Per project: open the directory with CLion, enable only the `debug-<board> preset` CMake profile, delete the auto-created CMake Application configurations, select the `<name> SWD` run configuration.

Then point to the wiring summary in [references/hardware.md](references/hardware.md) before the first flash.

## 6. Finish

Summarize: project path, board, stdio, build result, and the remaining manual CLion steps. Do not claim the firmware was flashed or tested on hardware: this skill cannot verify that.
