# predator-rgb

Per-zone RGB keyboard control for the **Acer Predator Triton 300 SE (PT314-51s)** and other Acer
models whose keyboard colour is driven by the `WMBH` gaming WMI methods.

The stock Linux drivers accept colour commands on this machine and the EC stores them correctly -
but the keyboard stays on its default blue. One bit decides it.

## The missing bit

The EC renders custom keyboard lighting only while its "PredatorSense is running" flag is set:
**EC register `0x03`, bit 4**, named `PSEE` in the DSDT. PredatorSense sets it on Windows. No Linux
driver does, and the ACPI tables declare the field but never write it. Without it:

* colour writes succeed, and read back correctly through WMI method `0x07`;
* brightness changes are visible, so the WMI -> EC -> LED path is demonstrably alive;
* the colour never changes.

Set the flag and the same writes render immediately. Fan control stays on automatic.

Register map, decoded from this laptop's own ACPI tables (`WMBH`, WMI GUID
`7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56`):

| register | meaning |
|---|---|
| `0x03` bit 4 | `PSEE` - custom lighting enable (the missing bit) |
| `0x17` / `0x18` / `0x19` | mode / speed / brightness |
| `0x1B` | effect direction |
| `0x1C`-`0x1E` | global colour, used by the firmware's own Fn-key brightness cycling |
| `0x1F` | zone-enable mask |
| `0x3C`-`0x47` | per-zone RGB |

Two details that cost time: the zone argument to WMI method 6 is a **bitmask** (1 / 2 / 4 for
left / middle / right), not an index; and the effects payload needs byte 3 set to 8 for wave.

## Use

```sh
./install.sh

predator-rgb static green
predator-rgb static red '#00ff88' blue      # left, middle, right
predator-rgb zone middle orange
predator-rgb effect wave --speed 6 --direction rtl
predator-rgb effect breathing --color purple
predator-rgb brightness 40
predator-rgb on | off | toggle | status
```

`predator-rgb-gui` is a GTK3 panel for the same thing. `predator-rgb.service` re-arms the flag and
restores your colours at boot and after suspend, since the EC forgets on power loss.

The helper that sets the EC flag refuses to run on any machine whose DMI product name is not a
model it has been verified on, so it cannot poke the EC of unrelated hardware.

## Fn+F4 also dimmed the screen

The EC steps the keyboard backlight itself, in firmware, with no key event needed. But the same key
additionally emits atkbd scancode `0xef`, which the kernel maps to `KEY_BRIGHTNESSDOWN` - so every
press dimmed the display as a side effect.

`udev/61-predator-pt314-51s.hwdb` maps that one scancode to `reserved`. The firmware's backlight
stepping is untouched, and the real screen-brightness keys keep working because they arrive over the
ACPI Video Bus rather than the AT keyboard. The rule is scoped by DMI so it can only ever match a
PT314-51s. To revert, delete it and run `systemd-hwdb update && udevadm trigger`.

The same file also silences Fn+F9, which decodes to scancode `0xcf` -> `KEY_END` and typed an End
keystroke into whatever had focus. There is no keyboard-backlight LED class on this machine for it
to drive, so it is silenced rather than remapped to something nothing would handle.

## Status

Developed and tested on one PT314-51s (board `Clubman_TLM`, BIOS V1.10), Ubuntu 22.04, kernel 6.8,
with the `facer` DKMS module providing `/dev/acer-gkbbl-*`. Per-zone colour, brightness and the
Breath / Neon / Wave / Shifting / Zoom effects all verified on real hardware. Reports from other
models are welcome - the `PSEE` flag is likely the same across the Predator/Nitro family, and
[an upstream PR](https://github.com/JafarAkhondali/acer-predator-turbo-and-rgb-keyboard-linux-module/pull/304)
adds it to the kernel driver so no userspace helper is needed.
