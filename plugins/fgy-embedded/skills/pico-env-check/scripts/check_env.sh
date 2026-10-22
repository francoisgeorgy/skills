#!/usr/bin/env bash
# Check the macOS environment for C development on Raspberry Pi Pico (RP2040)
# and Pico 2 (RP2350) with the Pico SDK, CLion, OpenOCD and a Debug Probe.
#
# Usage: check_env.sh [--offline]
#   --offline  skip the network lookup of the latest Pico SDK release
#
# Output, tab-separated, one record per line:
#   ROW      component  status  scope  found  note
#   CMD      order      command comment
#   VERDICT  board      build=ok|blocked  debug=ok|blocked
# status: ok | missing | update | remove | broken | optional | info
# scope:  all | pico | pico2 (which boards the item matters for)
# Commands are printed sorted by order: run them top to bottom.
# Never modifies anything. Compatible with macOS /bin/bash 3.2.
set -uo pipefail

offline=0
[[ "${1:-}" == "--offline" ]] && offline=1

TAB=$'\t'
CMDS=""
# Blockers, per board and stage.
b_build_all=0 b_build_pico2=0 b_debug_all=0 b_debug_pico=0 b_debug_pico2=0

row() { printf 'ROW\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5"; }
cmd() { CMDS="${CMDS}$1${TAB}$2${TAB}$3"$'\n'; }
first_line() { head -n1 | tr -d '\r'; }
# version_ge A B: true if A >= B (dotted numeric versions)
version_ge() { [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | head -n1)" == "$2" ]]; }
realpath_of() { python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null || echo "$1"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
    row "Operating system" info all "$(uname -s)" "This check targets macOS; commands may not apply"
fi

# Shell startup file for persistent exports.
case "${SHELL:-}" in
    */zsh)  rc="~/.zshrc" ;;
    */bash) rc="~/.bash_profile" ;;
    *)      rc="<your shell startup file>" ;;
esac

# ---------------------------------------------------------------------------
# Xcode Command Line Tools (git, python3, compiling OpenOCD HEAD)
# ---------------------------------------------------------------------------
if clt="$(xcode-select -p 2>/dev/null)"; then
    row "Xcode Command Line Tools" ok all "$clt" ""
    has_clt=1
else
    row "Xcode Command Line Tools" missing all "" "Provides git and python3; needed by Homebrew and to build OpenOCD HEAD"
    cmd 10 "xcode-select --install" "Install the Xcode Command Line Tools (GUI dialog)"
    has_clt=0
    b_build_all=1
fi

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------
BREW=""
if BREW="$(command -v brew)"; then
    row "Homebrew" ok all "$("$BREW" --version 2>/dev/null | first_line)" ""
else
    for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [[ -x "$p" ]] && BREW="$p" && break
    done
    if [[ -n "$BREW" ]]; then
        row "Homebrew" missing all "$BREW" "Installed but not on PATH; the checks below assume it is fixed"
        # Check the rest as it will be once the PATH is fixed.
        eval "$("$BREW" shellenv)"
        cmd 21 "echo 'eval \"\$($BREW shellenv)\"' >> $rc && eval \"\$($BREW shellenv)\"" "Put Homebrew on PATH"
    else
        row "Homebrew" missing all "" "Needed for all install commands below"
        cmd 20 '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' "Install Homebrew (official script; it explains and pauses before acting)"
        cmd 21 "echo 'eval \"\$(/opt/homebrew/bin/brew shellenv)\"' >> $rc && eval \"\$(/opt/homebrew/bin/brew shellenv)\"" "Put Homebrew on PATH (Apple Silicon prefix; /usr/local on Intel)"
    fi
fi

brew_q() { [[ -n "$BREW" ]] && "$BREW" "$@" 2>/dev/null; }
formula_installed() { brew_q list --formula --versions "$1" | first_line; }
cask_installed() { brew_q list --cask --versions "$1" | first_line; }

# Outdated brew packages among those installed (local index: run `brew update` first for fresh data).
OUTDATED=""
if [[ -n "$BREW" ]]; then
    names=""
    for f in cmake ninja picotool open-ocd; do [[ -n "$(formula_installed $f)" ]] && names="$names $f"; done
    casks=""
    [[ -n "$(cask_installed gcc-arm-embedded)" ]] && casks="gcc-arm-embedded"
    if [[ -n "$names$casks" ]]; then
        OUTDATED="$( { [[ -n "$names" ]] && brew_q outdated --formula $names; [[ -n "$casks" ]] && brew_q outdated --cask $casks; } | tr '\n' ' ')"
    fi
fi
is_outdated() { [[ " $OUTDATED " == *" $1 "* ]]; }

# ---------------------------------------------------------------------------
# git, python3
# ---------------------------------------------------------------------------
for t in git python3; do
    if p="$(command -v $t)" && v="$($t --version 2>&1 | first_line)" && [[ "$v" != *"xcode-select"* ]]; then
        row "$t" ok all "$v ($p)" ""
    else
        row "$t" missing all "" "Provided by the Xcode Command Line Tools"
        [[ $has_clt -eq 1 ]] && cmd 10 "xcode-select --install" "Install the Xcode Command Line Tools (GUI dialog)"
        b_build_all=1
    fi
done

# ---------------------------------------------------------------------------
# CMake: SDK needs >= 3.13, fgy-embedded project templates need >= 4.1
# ---------------------------------------------------------------------------
if p="$(command -v cmake)"; then
    v="$(cmake --version | first_line | awk '{print $3}')"
    if ! version_ge "$v" 3.13; then
        row "CMake" missing all "$v ($p)" "Pico SDK needs >= 3.13"
        b_build_all=1
        if [[ -n "$(formula_installed cmake)" ]]; then cmd 60 "brew upgrade cmake" "Upgrade CMake"; else cmd 50 "brew install cmake" "Install CMake"; fi
    elif ! version_ge "$v" 4.1; then
        row "CMake" update all "$v ($p)" "fgy-embedded project templates need >= 4.1"
        if [[ -n "$(formula_installed cmake)" ]]; then cmd 60 "brew upgrade cmake" "Upgrade CMake"; else cmd 50 "brew install cmake" "Install CMake (Homebrew, ahead of $p in PATH)"; fi
    elif is_outdated cmake; then
        row "CMake" update all "$v ($p)" "Newer Homebrew version available"
        cmd 60 "brew upgrade cmake" "Upgrade CMake"
    else
        row "CMake" ok all "$v ($p)" ""
    fi
else
    row "CMake" missing all "" "Required (>= 4.1 for fgy-embedded templates)"
    cmd 50 "brew install cmake" "Install CMake"
    b_build_all=1
fi

# ---------------------------------------------------------------------------
# Ninja (optional: CLion bundles one)
# ---------------------------------------------------------------------------
clion=""
for a in "$HOME/Applications/CLion.app" /Applications/CLion.app; do [[ -d "$a" ]] && clion="$a" && break; done
if p="$(command -v ninja)"; then
    if is_outdated ninja; then
        row "Ninja" update all "$(ninja --version) ($p)" "Newer Homebrew version available"
        cmd 60 "brew upgrade ninja" "Upgrade Ninja"
    else
        row "Ninja" ok all "$(ninja --version) ($p)" ""
    fi
elif [[ -n "$clion" ]]; then
    row "Ninja" optional all "bundled with CLion" "CLion uses its own; install for command-line preset builds"
    cmd 70 "brew install ninja" "Optional: Ninja for command-line builds"
else
    row "Ninja" optional all "" "Needed for CMake presets outside CLion"
    cmd 70 "brew install ninja" "Optional: Ninja for command-line builds"
fi

row "CLion" "$([[ -n "$clion" ]] && echo ok || echo optional)" all "${clion:-not found}" ""

# ---------------------------------------------------------------------------
# Arm GNU toolchain (Homebrew cask gcc-arm-embedded)
# ---------------------------------------------------------------------------
# Incomplete core formulae that clash with the cask (no newlib or no gdb).
bad_formulae=""
for f in arm-none-eabi-gcc arm-none-eabi-binutils arm-none-eabi-gdb; do
    [[ -n "$(formula_installed $f)" ]] && bad_formulae="$bad_formulae $f"
done
cask_v="$(cask_installed gcc-arm-embedded | awk '{print $2}')"
if [[ -n "$bad_formulae" ]]; then
    row "Homebrew formulae${bad_formulae}" remove all "installed" "Incomplete toolchain that clashes with the gcc-arm-embedded cask"
    cmd 40 "brew uninstall${bad_formulae}" "Remove the incomplete Homebrew Arm formulae"
fi

toolchain_fix=0
for t in arm-none-eabi-gcc arm-none-eabi-g++ arm-none-eabi-gdb; do
    if p="$(command -v $t)" && v="$($t --version 2>/dev/null | first_line)" && [[ -n "$v" ]]; then
        row "$t" ok all "$v" "$(realpath_of "$p")"
    else
        row "$t" missing all "" "From the gcc-arm-embedded cask"
        toolchain_fix=1
        if [[ "$t" == arm-none-eabi-gdb ]]; then b_debug_all=1; else b_build_all=1; fi
    fi
done
if command -v arm-none-eabi-gcc >/dev/null; then
    libc="$(arm-none-eabi-gcc -print-file-name=libc.a 2>/dev/null)"
    if [[ "$libc" == /* && -f "$libc" ]]; then
        row "newlib (C library)" ok all "found" ""
    else
        row "newlib (C library)" missing all "" "Compiler has no target C library"
        toolchain_fix=1; b_build_all=1
    fi
fi
if [[ $toolchain_fix -eq 1 ]]; then
    if [[ -n "$cask_v" ]]; then
        cmd 50 "brew reinstall --cask gcc-arm-embedded" "Reinstall the Arm GNU toolchain"
    else
        cmd 50 "brew install --cask gcc-arm-embedded" "Install the Arm GNU toolchain (gcc, g++, gdb, newlib)"
    fi
elif [[ -n "$cask_v" ]] && is_outdated gcc-arm-embedded; then
    row "gcc-arm-embedded (cask)" update all "$cask_v" "Newer version available"
    cmd 60 "brew upgrade --cask gcc-arm-embedded" "Upgrade the Arm GNU toolchain"
fi

# ---------------------------------------------------------------------------
# Pico SDK
# ---------------------------------------------------------------------------
latest=""
if [[ $offline -eq 0 ]] && command -v git >/dev/null; then
    latest="$(GIT_TERMINAL_PROMPT=0 git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=10 \
        ls-remote --tags --refs https://github.com/raspberrypi/pico-sdk.git 2>/dev/null \
        | awk -F/ '{print $3}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)"
fi
sdk_tag="${latest:-<release tag, e.g. 2.2.0>}"
sdk_ok=0 sdk_v=""
if [[ -z "${PICO_SDK_PATH:-}" ]]; then
    guess=""
    for d in "$HOME/dev/pico/pico-sdk" "$HOME/pico-sdk" "$HOME/pico/pico-sdk"; do
        [[ -f "$d/external/pico_sdk_import.cmake" ]] && guess="$d" && break
    done
    if [[ -n "$guess" ]]; then
        row "Pico SDK (PICO_SDK_PATH)" missing all "found at $guess" "PICO_SDK_PATH not set"
        cmd 80 "echo 'export PICO_SDK_PATH=\"$guess\"' >> $rc && export PICO_SDK_PATH=\"$guess\"" "Point PICO_SDK_PATH to the existing SDK"
    else
        row "Pico SDK (PICO_SDK_PATH)" missing all "" "PICO_SDK_PATH not set, no SDK found"
        cmd 80 "git clone -b $sdk_tag https://github.com/raspberrypi/pico-sdk.git ~/dev/pico/pico-sdk" "Download the Pico SDK"
        cmd 81 "git -C ~/dev/pico/pico-sdk submodule update --init --recursive" "Fetch SDK submodules (TinyUSB, cyw43, lwIP...)"
        cmd 82 "echo 'export PICO_SDK_PATH=\"\$HOME/dev/pico/pico-sdk\"' >> $rc && export PICO_SDK_PATH=\"\$HOME/dev/pico/pico-sdk\"" "Set PICO_SDK_PATH"
    fi
    b_build_all=1
elif [[ ! -f "$PICO_SDK_PATH/external/pico_sdk_import.cmake" ]]; then
    row "Pico SDK (PICO_SDK_PATH)" missing all "$PICO_SDK_PATH" "Not a Pico SDK checkout"
    b_build_all=1
else
    vf="$PICO_SDK_PATH/pico_sdk_version.cmake"
    if [[ -f "$vf" ]]; then
        sdk_v="$(sed -nE 's/^ *set\(PICO_SDK_VERSION_(MAJOR|MINOR|REVISION) ([0-9]+)\).*/\2/p' "$vf" | paste -sd. -)"
    fi
    sdk_ok=1
    is_git=0
    git -C "$PICO_SDK_PATH" rev-parse --git-dir >/dev/null 2>&1 && is_git=1
    if [[ -n "$sdk_v" ]] && ! version_ge "$sdk_v" 2.0.0; then
        row "Pico SDK" update pico2 "$sdk_v ($PICO_SDK_PATH)" "RP2350 needs SDK >= 2.0.0"
        b_build_pico2=1
    elif [[ -n "$latest" && -n "$sdk_v" ]] && ! version_ge "$sdk_v" "$latest"; then
        row "Pico SDK" update all "$sdk_v ($PICO_SDK_PATH)" "Release $latest available"
    else
        row "Pico SDK" ok all "${sdk_v:-version unknown} ($PICO_SDK_PATH)" "$([[ -z "$latest" ]] && echo 'latest release not checked (offline)')"
    fi
    if [[ -n "$sdk_v" ]] && { ! version_ge "$sdk_v" 2.0.0 || { [[ -n "$latest" ]] && ! version_ge "$sdk_v" "$latest"; }; }; then
        if [[ $is_git -eq 1 ]]; then
            dirty=""
            [[ -n "$(git -C "$PICO_SDK_PATH" status --porcelain --ignore-submodules 2>/dev/null)" ]] && dirty=" (local changes in the SDK: commit or stash them first)"
            cmd 85 "git -C \"\$PICO_SDK_PATH\" fetch --tags && git -C \"\$PICO_SDK_PATH\" checkout $sdk_tag" "Switch the SDK to the latest release$dirty"
            cmd 86 "git -C \"\$PICO_SDK_PATH\" submodule update --init --recursive" "Update SDK submodules to match"
        else
            cmd 85 "git clone -b $sdk_tag https://github.com/raspberrypi/pico-sdk.git <new path>" "SDK is not a git checkout: clone the release, then point PICO_SDK_PATH to it"
        fi
    fi

    # Submodules: TinyUSB (USB stdio), cyw43-driver and lwIP (W boards), btstack, mbedtls.
    if [[ $is_git -eq 1 ]]; then
        sub="$(git -C "$PICO_SDK_PATH" submodule status 2>/dev/null)"
        uninit="$(printf '%s\n' "$sub" | awk '/^-/{print $2}' | tr '\n' ' ')"
        if [[ -n "$uninit" ]]; then
            row "SDK submodules" missing all "" "Not initialized: $uninit"
            cmd 86 "git -C \"\$PICO_SDK_PATH\" submodule update --init --recursive" "Fetch SDK submodules"
            b_build_all=1
        else
            row "SDK submodules" ok all "$(printf '%s\n' "$sub" | grep -c .) initialized" ""
        fi
    fi
fi

# ---------------------------------------------------------------------------
# picotool (optional for SWD; .uf2 output; the SDK otherwise builds it from git)
# ---------------------------------------------------------------------------
pt_req=""
if [[ $sdk_ok -eq 1 && -f "$PICO_SDK_PATH/tools/CMakeLists.txt" ]]; then
    pt_req="$(sed -n 's/.*set(picotool_VERSION_REQUIRED \([0-9.]*\)).*/\1/p' "$PICO_SDK_PATH/tools/CMakeLists.txt" | head -n1)"
fi
if p="$(command -v picotool)"; then
    pv="$(picotool version 2>/dev/null | first_line | awk '{print $2}' | tr -d v)"
    # The SDK accepts the same major version, not older than required.
    if [[ -n "$pt_req" && -n "$pv" ]] && { [[ "${pv%%.*}" != "${pt_req%%.*}" ]] || ! version_ge "$pv" "$pt_req"; }; then
        row "picotool" update all "$pv ($p)" "SDK requires $pt_req (same major); otherwise it builds picotool from git"
        cmd 60 "brew upgrade picotool" "Upgrade picotool"
    elif is_outdated picotool; then
        row "picotool" update all "$pv ($p)" "Newer Homebrew version available"
        cmd 60 "brew upgrade picotool" "Upgrade picotool"
    else
        row "picotool" ok all "$pv ($p)" "${pt_req:+SDK requires $pt_req}"
    fi
else
    row "picotool" optional all "" "For .uf2 output; without it the SDK downloads and builds it at configure time"
    cmd 70 "brew install picotool" "Recommended: picotool for .uf2 output"
fi

# ---------------------------------------------------------------------------
# OpenOCD: RP2040 needs target/rp2040.cfg, RP2350 needs target/rp2350.cfg
# (only in OpenOCD master / Raspberry Pi fork, not in the 0.12.0 release)
# ---------------------------------------------------------------------------
ocd_formula="$(formula_installed open-ocd)"
ocd_linked=""
if [[ -n "$ocd_formula" ]]; then
    ocd_linked="$(readlink "$("$BREW" --prefix)/opt/open-ocd" 2>/dev/null | sed 's|.*/||')"
fi
head_cmd="brew uninstall --force open-ocd && brew install --HEAD open-ocd"
if p="$(command -v openocd)"; then
    real="$(realpath_of "$p")"
    out="$(openocd --version 2>&1)"
    v="$(printf '%s\n' "$out" | grep -m1 'Open On-Chip Debugger')"
    if [[ -z "$v" ]]; then
        row "OpenOCD" broken all "$real" "Does not start: $(printf '%s\n' "$out" | first_line)"
        b_debug_all=1
        if [[ "$real" == */Cellar/open-ocd/* ]]; then
            cmd 55 "$head_cmd" "Rebuild OpenOCD from master (a HEAD build breaks when a library it links, e.g. jimtcl, is upgraded)"
        fi
    else
        scripts="$(cd "$(dirname "$real")/.." && pwd)/share/openocd/scripts"
        has_dap=0 has_2040=0 has_2350=0
        [[ -f "$scripts/interface/cmsis-dap.cfg" ]] && has_dap=1
        [[ -f "$scripts/target/rp2040.cfg" ]] && has_2040=1
        [[ -f "$scripts/target/rp2350.cfg" ]] && has_2350=1
        # Homebrew keg this executable belongs to, if any.
        keg="$(printf '%s' "$real" | sed -n 's|.*/Cellar/open-ocd/\([^/]*\)/.*|\1|p')"
        kind="$([[ "$keg" == HEAD* ]] && echo "Homebrew HEAD build (master) $keg" || { [[ -n "$keg" ]] && echo "Homebrew $keg" || echo "Not from Homebrew: $real"; })"
        sup_pico="$([[ $has_2040 -eq 1 ]] && echo supported || echo "NOT supported")"
        sup_pico2="$([[ $has_2350 -eq 1 ]] && echo supported || echo "NOT supported")"
        if [[ $has_2350 -eq 1 ]]; then
            row "OpenOCD" ok all "$v" "Pico: $sup_pico, Pico 2: $sup_pico2. $kind"
        else
            row "OpenOCD" update pico2 "$v" "Pico: $sup_pico, Pico 2: $sup_pico2 (no target/rp2350.cfg). $kind"
        fi
        if [[ $has_dap -eq 1 ]]; then row "OpenOCD interface/cmsis-dap.cfg" ok all "found" ""; else row "OpenOCD interface/cmsis-dap.cfg" missing all "" "Debug Probe interface script"; b_debug_all=1; fi
        if [[ $has_2040 -eq 1 ]]; then row "OpenOCD target/rp2040.cfg" ok pico "found" ""; else row "OpenOCD target/rp2040.cfg" missing pico "" "RP2040 target script"; b_debug_pico=1; fi
        if [[ $has_2350 -eq 1 ]]; then
            row "OpenOCD target/rp2350.cfg" ok pico2 "found" ""
        else
            note="Not in OpenOCD 0.12.0: needs master (Homebrew --HEAD) or the Raspberry Pi fork"
            [[ -n "$keg" && "$ocd_formula" == *HEAD-* && "$keg" != HEAD* ]] && note="A HEAD build is installed but $keg is the linked one"
            row "OpenOCD target/rp2350.cfg" missing pico2 "" "$note"
            b_debug_pico2=1
            if [[ -n "$keg" ]]; then
                cmd 55 "$head_cmd" "Replace OpenOCD with a build from master (keeps RP2040 support)"
            elif [[ -n "$ocd_formula" && -f "$("$BREW" --prefix)/share/openocd/scripts/target/rp2350.cfg" ]]; then
                cmd 56 "export PATH=\"$("$BREW" --prefix)/bin:\$PATH\"" "Homebrew's OpenOCD ($ocd_linked) already supports Pico 2 but is shadowed by $real: put it first in PATH (in $rc) and point CLion to it"
            elif [[ -n "$ocd_formula" ]]; then
                cmd 55 "$head_cmd" "Replace Homebrew's OpenOCD with a build from master, then put $("$BREW" --prefix)/bin ahead of $(dirname "$real") in PATH"
            elif [[ -n "$BREW" || "$CMDS" == *"brew"* ]]; then
                cmd 55 "brew install --HEAD open-ocd" "Install OpenOCD from master, ahead of $real in PATH (keeps RP2040 support)"
            fi
        fi
    fi
    others="$(type -ap openocd | sed -n '2,$p' | tr '\n' ' ')"
    [[ -n "$others" ]] && row "OpenOCD (other copies on PATH)" info all "$others" "Shadowed by $p; CLion must point to the one checked here"
else
    row "OpenOCD" missing all "" "Needed to flash and debug through the Debug Probe"
    b_debug_all=1
    cmd 55 "brew install --HEAD open-ocd" "Install OpenOCD from master (RP2040 and RP2350 support)"
fi

# ---------------------------------------------------------------------------
# Verdicts and commands
# ---------------------------------------------------------------------------
v_build_pico=$(( b_build_all ))
v_build_pico2=$(( b_build_all || b_build_pico2 ))
v_debug_pico=$(( v_build_pico || b_debug_all || b_debug_pico ))
v_debug_pico2=$(( v_build_pico2 || b_debug_all || b_debug_pico2 ))
st() { [[ $1 -eq 0 ]] && echo ok || echo blocked; }
printf 'VERDICT\tpico\tbuild=%s\tdebug=%s\n' "$(st $v_build_pico)" "$(st $v_debug_pico)"
printf 'VERDICT\tpico2\tbuild=%s\tdebug=%s\n' "$(st $v_build_pico2)" "$(st $v_debug_pico2)"

if [[ "$CMDS" == *"brew "* && -n "$BREW" ]]; then
    cmd 30 "brew update" "Refresh Homebrew before installing or upgrading"
fi
if [[ -n "$CMDS" ]]; then
    # Sort by order, drop duplicate commands, keep the first comment.
    printf '%s' "$CMDS" | sort -t"$TAB" -k1,1n -s | awk -F'\t' '!seen[$2]++ {print "CMD\t" $0}'
fi
exit 0
