# Wiring the Raspberry Pi Debug Probe

Disconnect target power while wiring.

## SWD (probe port D)

| Probe | Pico / Pico W debug pad |
| --- | --- |
| `SC` (orange) | `SWCLK` |
| `GND` (black) | `GND` |
| `SD` (yellow) | `SWDIO` |

- Check pad labels on the board; do not rely on left-to-right position. Pico H can use the 3-pin JST-SH cable directly.
- Signals are 3.3 V. Never connect 5 V to the SWD pads.
- The SWD cable does not power the Pico: power it through its own USB. With separately powered equipment, connect GND first.

## UART (probe port U), only for `--stdio uart`

| Probe | Pico |
| --- | --- |
| `RX` | `GP0` (UART0 TX, pin 1) |
| `TX` | `GP1` (UART0 RX, pin 2) |
| `GND` | `GND` |

The SDK's default UART baud rate is 115200. The probe's serial port and the Pico's USB CDC port (`--stdio usb`) are different devices. On macOS, list them with `ls /dev/cu.usbmodem*` and identify them with `ioreg -r -c IOSerialBSDClient -l`.

## Flash and debug outside CLion

Stop any CLion debug session first.

```sh
# one-shot: flash, verify, reset, exit
openocd -f openocd-rp2040-cmsis-dap.cfg -c "program build/<board>/<name>.elf verify reset exit"

# manual debug: keep the server running...
openocd -f openocd-rp2040-cmsis-dap.cfg
# ...and in another terminal
arm-none-eabi-gdb build/<board>/<name>.elf
(gdb) target remote localhost:3333
(gdb) monitor reset halt
(gdb) load
(gdb) monitor reset init
(gdb) break main
(gdb) continue
```

If the connection is unreliable, lower `adapter speed` in `openocd-rp2040-cmsis-dap.cfg` (e.g. `1000`).
