#!/usr/bin/env python3
"""vice-labels.py: turn KickAssembler's VICE symbol file into a label file for
the VICE monitor, without equat.s's constants.

    tools/vice-labels.py <file.vs> <file.labels> [--range START-END]

KickAssembler's -vicesymbols writes every .label it knows, including
equat.s's constants (flag masks, character codes, BASIC variable numbers...),
which the monitor would show as labels for low memory: e.g. both
.flag_mnt_r_mask and .ascii_backspace for $0008. This drops those by name and
keeps the real addresses (flag_..._addr, ltk_..., *_address, ...).

--range keeps only labels from START to END (hex, e.g. c000-cfff), e.g. just
the module being debugged. --clear starts the file with "cl" (clear labels);
without it, several files can be loaded together, e.g. the ML and a module.

In the VICE monitor (Alt+H):
    ll "build/asm/ml.labels"
    ll "build/asm/visual.labels"
then e.g.  r  (where it is),  d visual5,  break visual5
"""
import re
import sys

# names of constants (not addresses) in equat.s
CONSTANT = re.compile(
    r"^(flag_\w+_mask"          # lightbar bit masks (flag_..._addr are addresses)
    r"|var_\w+"                 # BASIC variable numbers
    r"|cursor_\w+"              # PETSCII control/colour codes
    r"|ascii_\w+"               # ASCII codes
    r"|function_key_\w+"        # encoded function key codes
    r"|editor_\w+"              # editor flag bits (not "editor" itself)
    r"|passmode_\w+"            # password mode flag bits
    r"|r6510_\w+"               # values for $01 (not "r6510" itself)
    r")$")


def main(argv):
    import argparse
    ap = argparse.ArgumentParser(description="KickAssembler .vs -> VICE monitor labels")
    ap.add_argument("src", help="KickAssembler -vicesymbols file (.vs)")
    ap.add_argument("dst", help="label file to write")
    ap.add_argument("--range", help="keep only START-END (hex), e.g. c000-cfff")
    ap.add_argument("--clear", action="store_true",
                    help="start the file with cl, clearing the monitor's labels")
    a = ap.parse_args(argv[1:])
    lo, hi = 0, 0xFFFF
    if a.range:
        lo, hi = (int(x, 16) for x in a.range.split("-"))
    src, dst = a.src, a.dst

    kept, dropped = [], 0
    with open(src) as f:
        for line in f:
            # al C:c000 .label
            m = re.match(r"al\s+C:([0-9a-fA-F]+)\s+\.(\S+)", line)
            if not m:
                continue
            addr, name = int(m.group(1), 16), m.group(2)
            if CONSTANT.match(name) or not lo <= addr <= hi:
                dropped += 1
                continue
            kept.append((addr, name))

    with open(dst, "w") as f:
        if a.clear:
            f.write("cl\n")  # clear the monitor's old labels first
        for addr, name in sorted(kept):
            f.write(f"al C:{addr:04x} .{name}\n")
    print(f"{dst}: {len(kept)} labels ({dropped} constants or out of range dropped)")


if __name__ == "__main__":
    main(sys.argv)
