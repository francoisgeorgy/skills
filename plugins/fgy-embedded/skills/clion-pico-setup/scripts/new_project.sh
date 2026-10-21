#!/usr/bin/env bash
# Create a new Raspberry Pi Pico (RP2040) C project configured for CLion,
# OpenOCD and the Raspberry Pi Debug Probe.
#
# Usage: new_project.sh --name NAME --dir PARENT_DIR [--board pico|pico_w]
#                       [--stdio usb|uart|none] [--gdb PATH] [--no-git]
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$SKILL_DIR/assets/template"

name="" parent="" board="pico_w" stdio="usb" gdb="" git_init=1

usage() { sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
die() { echo "error: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)  name="${2:-}"; shift 2 ;;
        --dir)   parent="${2:-}"; shift 2 ;;
        --board) board="${2:-}"; shift 2 ;;
        --stdio) stdio="${2:-}"; shift 2 ;;
        --gdb)   gdb="${2:-}"; shift 2 ;;
        --no-git) git_init=0; shift ;;
        -h|--help) usage 0 ;;
        *) echo "unknown option: $1" >&2; usage 1 ;;
    esac
done

[[ -n "$name" && -n "$parent" ]] || usage 1
# The name is used as CMake project, target and C string: keep it an identifier.
[[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "--name must match [A-Za-z_][A-Za-z0-9_]* (got '$name')"

case "$board" in
    pico)   board_name="Raspberry Pi Pico" ;;
    pico_w) board_name="Raspberry Pi Pico W" ;;
    *) die "--board must be pico or pico_w (got '$board')" ;;
esac

case "$stdio" in
    usb)  stdio_usb=1 stdio_uart=0
          stdio_label_en="USB CDC"
          stdio_label_fr="USB CDC" ;;
    uart) stdio_usb=0 stdio_uart=1
          stdio_label_en="UART0 (GP0/GP1), read through the probe's U port"
          stdio_label_fr="UART0 (GP0/GP1), lu via le port U de la sonde" ;;
    none) stdio_usb=0 stdio_uart=0
          stdio_label_en="disabled"
          stdio_label_fr="désactivé" ;;
    *) die "--stdio must be usb, uart or none (got '$stdio')" ;;
esac

if [[ -z "$gdb" ]]; then
    gdb="$(command -v arm-none-eabi-gdb || true)"
    [[ -n "$gdb" ]] || gdb="/path/to/arm-none-eabi-gdb"
fi

preset="debug-${board//_/-}"

sdk_version="inconnu"
if [[ -n "${PICO_SDK_PATH:-}" && -d "$PICO_SDK_PATH" ]]; then
    sdk_version="$(git -C "$PICO_SDK_PATH" describe --tags --always 2>/dev/null || echo inconnu)"
fi

[[ -d "$parent" ]] || die "parent directory does not exist: $parent"
dest="$(cd "$parent" && pwd)/$name"
if [[ -e "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
    die "destination exists and is not empty: $dest"
fi

mkdir -p "$dest"
cp -R "$TEMPLATE/." "$dest/"
mv "$dest/gitignore" "$dest/.gitignore"
mv "$dest/aiignore" "$dest/.aiignore"
mv "$dest/.run/@PROJECT@ SWD.run.xml" "$dest/.run/$name SWD.run.xml"

# Escape sed replacement metacharacters (&, \ and the | delimiter).
esc() { printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'; }

while IFS= read -r -d '' f; do
    # Write to a temp file: `sed -i` syntax differs between BSD and GNU sed.
    sed \
        -e "s|@PROJECT@|$(esc "$name")|g" \
        -e "s|@BOARD@|$(esc "$board")|g" \
        -e "s|@BOARD_NAME@|$(esc "$board_name")|g" \
        -e "s|@PRESET@|$(esc "$preset")|g" \
        -e "s|@STDIO_USB@|$stdio_usb|g" \
        -e "s|@STDIO_UART@|$stdio_uart|g" \
        -e "s|@STDIO_LABEL_EN@|$(esc "$stdio_label_en")|g" \
        -e "s|@STDIO_LABEL_FR@|$(esc "$stdio_label_fr")|g" \
        -e "s|@GDB@|$(esc "$gdb")|g" \
        -e "s|@SDK_VERSION@|$(esc "$sdk_version")|g" \
        "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done < <(find "$dest" -type f -print0)

if grep -rl '@[A-Z_]*@' "$dest" >/dev/null 2>&1; then
    die "unreplaced placeholders remain: $(grep -rl '@[A-Z_]*@' "$dest" | tr '\n' ' ')"
fi

if [[ $git_init -eq 1 ]]; then
    git -C "$dest" init -q
fi

cat <<EOF
created:  $dest
board:    $board
stdio:    $stdio
preset:   $preset
gdb:      $gdb
sdk:      ${PICO_SDK_PATH:-<PICO_SDK_PATH not set>} ($sdk_version)
EOF
