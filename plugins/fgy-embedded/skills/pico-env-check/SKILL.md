---
name: pico-env-check
description: Check whether this Mac has a working environment for C development on Raspberry Pi Pico / Pico W (RP2040) and Pico 2 / Pico 2 W (RP2350) with the Pico SDK, CLion, OpenOCD and a Raspberry Pi Debug Probe. Checks Homebrew, Xcode Command Line Tools, CMake, Ninja, the Arm GNU toolchain (gcc, g++, gdb, newlib), the Pico SDK (version, submodules, latest release), picotool and OpenOCD (RP2040 and RP2350 target scripts, broken HEAD builds), then reports what is in place, missing, outdated or to remove, with the Homebrew commands to fix it. Use when the user asks to check, verify, diagnose or audit their Pico / Pico 2 / RP2040 / RP2350 development setup or toolchain.
---

# Pico / Pico 2 environment check

Runs one read-only script that checks everything needed to build, flash and debug both RP2040 and RP2350 boards, then turns its output into a report. Always checks both board families; no parameters to ask for.

## 1. Run the check

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/check_env.sh"
```

Add `--offline` only if the user asks for it or the network is unavailable: it skips the lookup of the latest Pico SDK release. The script takes about 10 seconds, never modifies anything and always exits 0. Do not run the fix commands yourself unless the user asks: they install, remove or rebuild software.

## 2. Read the output

Tab-separated records:

| Record | Fields |
| --- | --- |
| `ROW` | component, status, scope, found, note |
| `VERDICT` | board (`pico` = RP2040, `pico2` = RP2350), `build=ok\|blocked`, `debug=ok\|blocked` |
| `CMD` | order, command, comment (already sorted and deduplicated) |

Status: `ok`, `missing`, `update`, `remove`, `broken`, `optional`, `info`. Scope: `all` (both families), `pico` (RP2040 only), `pico2` (RP2350 only).

`debug` covers flashing and debugging over SWD (OpenOCD + GDB); it is blocked whenever `build` is.

## 3. Write the report

In the user's language, in this order. Keep the commands exactly as printed by the script; only translate comments and notes.

1. **Summary**, one line per board family, from the `VERDICT` records: for example "Pico (RP2040): build OK, flash/debug OK" and "Pico 2 (RP2350): build OK, flash/debug blocked (OpenOCD)". Name the blocking component.
2. **Table**, one line per `ROW`:

   | Component | Status | Pico | Pico 2 | Found | Note |
   | --- | --- | --- | --- | --- | --- |

   - Status in words: OK, missing, update, remove, broken, optional, info.
   - Pico and Pico 2 columns: from scope. `all` marks both; `pico` marks Pico and shows `n/a` for Pico 2; `pico2` the reverse. Use "required" or "optional" for the marked columns, following the status (`optional` rows are optional for both).
   - Shorten long "found" values (keep the version and the relevant path).
3. **Commands to run**, only if there are `CMD` records, as one `sh` block per group, in the printed order, with the comment as a line above each command:
   - If a command installs Homebrew (order 20), start with a short "Install Homebrew first" section: the install command, then the PATH command (order 21), and say that the remaining `brew` commands need a new terminal or the `eval` line. If the Xcode Command Line Tools are missing (order 10), they come first: the Homebrew installer also asks for them.
   - Then removals (`brew uninstall`), installs, upgrades, then the Pico SDK commands (`git`), then optional items, labelled as optional.
   - Mention that `brew outdated` information comes from the local Homebrew index; `brew update` (included when relevant) refreshes it.
4. **After fixing**: tell the user to open a new terminal (exports added to the shell startup file) and to run the check again. If OpenOCD changed, CLion's OpenOCD location (Settings > Build, Execution, Deployment > Embedded Development) must point to the checked executable.

## Notes for specific results

- **OpenOCD and RP2350**: the `OpenOCD` row's note always starts with `Pico: supported|NOT supported, Pico 2: supported|NOT supported`, then where the executable comes from (Homebrew HEAD build, Homebrew release, or another path). Keep that statement in the report's Note column. `target/rp2350.cfg` is not in the OpenOCD 0.12.0 release (Homebrew's stable `open-ocd`); a HEAD build (`brew install --HEAD open-ocd`) is master and supports both families.
- **OpenOCD that supports Pico 2**: no command is printed, and do not suggest updating, upgrading or rebuilding it, even for a HEAD build. Only if the user asks how to refresh a HEAD build: `brew upgrade --fetch-HEAD open-ocd` (`brew upgrade` skips HEAD builds).
- **OpenOCD shadowed in PATH**: if Homebrew's OpenOCD already supports Pico 2 but another `openocd` comes first in PATH, the printed fix is a PATH change, not a reinstall.
- **OpenOCD `broken`**: a HEAD build links Homebrew libraries at build time (jimtcl, capstone, hidapi, libftdi, libusb). Upgrading one of them to a new major library version, as happened with jimtcl, leaves the binary unable to start (`dyld: Library not loaded`). Rebuilding fixes it; warn that it can happen again after a future `brew upgrade`.
- **"A HEAD build is installed but ... is the linked one"**: both the 0.12.0 bottle and a HEAD build are installed and the stable one is active. The printed command removes both and rebuilds from master; the HEAD keg alone may be broken anyway (see above).
- **Arm toolchain**: only the `gcc-arm-embedded` cask is complete (gcc, g++, gdb, newlib). The core formulae `arm-none-eabi-gcc` / `-binutils` / `-gdb` are flagged `remove` because they lack newlib or GDB and clash with the cask.
- **CMake**: the Pico SDK needs >= 3.13; the fgy-embedded project templates (`clion-pico-setup`, `clion-pico2-setup`) need >= 4.1, hence `update` between the two.
- **Pico SDK update**: offered when a newer release tag exists. Not urgent unless the row has scope `pico2` (SDK < 2.0.0, no RP2350 support). A newer SDK can require a newer picotool: rerun the check after switching.
- **Ninja / picotool `optional`**: CLion bundles Ninja; picotool is only needed for `.uf2` output, but without it the SDK downloads and builds picotool at configure time (needs network).
- The script checks the tools found on PATH. CLion may be configured with other executables (toolchain `Pico ARM`, OpenOCD location); say so if an `info` row reports other copies on PATH.

Report only what the script found; do not claim that the Debug Probe or a board works, the script does not check hardware.
