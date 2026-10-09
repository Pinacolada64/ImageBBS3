#!/usr/bin/env bash
# start-ccgms.sh: run the CCGMS 2021 terminal program in VICE (x64sc), with
# its own tcpser as the modem, to call the Image BBS run by start-image-bbs.sh
#
#   start-ccgms.sh
#
# - A second tcpser emulates the caller's Hayes modem: VICE's emulated
#   SwiftLink talks to it on $MODEM_PORT, and it dials out over telnet.
#   (tcpser also listens for incoming calls on $TELNET_PORT; nothing uses that.)
# - In CCGMS, set the modem type to "Swift / Turbo DE" at $BAUD bps, then go
#   to terminal mode and dial the BBS's tcpser:
#     atdt127.0.0.1:6400
# - Drive 8 (1541) holds a working copy of the CCGMS disk in $RUN_DIR, made
#   only if it doesn't exist yet, so CCGMS can save its settings and phone
#   book. Delete it to start over from $CCGMS_D64.
# - tcpser is stopped when VICE exits.
# - The remote monitor is switched off (+remotemonitor) so this VICE doesn't
#   compete with the BBS's VICE for its port, and the user port RS-232 is
#   switched off (-userportdevice 0) so only the SwiftLink uses the modem.
#
# Logs: $LOG_DIR/tcpser.log and $LOG_DIR/vice.log
#
#   TCPSER_LOG_LEVEL   0 (none) - 7 (everything); default 4 (info)
#   TCPSER_TRACE       data to trace, any of: s = from the C64, S = to the C64,
#                      m/M = modem in/out, i/I = IP (BBS side) in/out
#   TCPSER_INVERT_DCD  1 inverts DCD (tcpser -I); default 0

set -euo pipefail

# --- disk ---
CCGMS_D64="$HOME/Documents/c64/ccgms 2021.d64"
CCGMS_PRG="ccgms 2021"
RUN_DIR="$HOME/Documents/c64/ccgms-run"
WORK_D64="$RUN_DIR/ccgms.d64"

# --- modem (tcpser) ---
TCPSER="$HOME/bin/tcpser/tcpser"
MODEM_PORT=25239   # VICE <-> tcpser, on 127.0.0.1 only (the BBS uses 25238)
TELNET_PORT=6401   # tcpser's incoming-call port (the BBS uses 6400)
BAUD=19200         # the same as the BBS; CCGMS's SwiftLink driver goes to 38400
TCPSER_LOG_LEVEL=${TCPSER_LOG_LEVEL:-4}
TCPSER_TRACE=${TCPSER_TRACE:-}
TCPSER_INVERT_DCD=${TCPSER_INVERT_DCD:-0}

# --- ROMs ---
VICE_ROMS="$HOME/.local/share/vice/C64"
JIFFYDOS="$HOME/Documents/c64/JiffyDOS"
KERNAL="$JIFFYDOS/JDOS64.rom"
DOS1541="$JIFFYDOS/JiffyC1541.ROM"
BASIC="$VICE_ROMS/basic-901226-01.bin"
CHARGEN="$VICE_ROMS/chargen-901225-01.bin"

LOG_DIR="$RUN_DIR/logs"

die() { echo "start-ccgms: $*" >&2; exit 1; }

for f in "$TCPSER" "$KERNAL" "$DOS1541" "$BASIC" "$CHARGEN"; do
	[ -e "$f" ] || die "not found: $f"
done
command -v x64sc > /dev/null || die "x64sc (VICE) isn't on the PATH"

mkdir -p "$RUN_DIR" "$LOG_DIR"

# --- working copy of the disk ---
if [ ! -f "$WORK_D64" ]; then
	[ -f "$CCGMS_D64" ] || die "$CCGMS_D64 not found"
	cp "$CCGMS_D64" "$WORK_D64"
	echo "Made $WORK_D64 from $CCGMS_D64"
fi

# --- tcpser ---
port_in_use() { ss -ltn 2>/dev/null | grep -q ":$1\b"; }
for p in "$MODEM_PORT" "$TELNET_PORT"; do
	port_in_use "$p" && die "port $p is already in use (is another tcpser running?)"
done

"$TCPSER" -s "$BAUD" -v "127.0.0.1:$MODEM_PORT" -p "$TELNET_PORT" \
	-l "$TCPSER_LOG_LEVEL" ${TCPSER_TRACE:+-t "$TCPSER_TRACE"} \
	$( [ "$TCPSER_INVERT_DCD" = 1 ] && echo -I ) -L "$LOG_DIR/tcpser.log" &
TCPSER_PID=$!
trap 'kill "$TCPSER_PID" 2> /dev/null || true' EXIT

# wait up to 5 seconds for tcpser to listen for VICE
for _ in $(seq 50); do
	port_in_use "$MODEM_PORT" && break
	kill -0 "$TCPSER_PID" 2> /dev/null || die "tcpser stopped: see $LOG_DIR/tcpser.log"
	sleep 0.1
done
port_in_use "$MODEM_PORT" || die "tcpser isn't listening on port $MODEM_PORT"
port_in_use 6400 || echo "note: nothing is listening on port 6400 yet; start the BBS with start-image-bbs.sh before dialing"
echo "tcpser: in CCGMS, dial atdt127.0.0.1:6400 (log: $LOG_DIR/tcpser.log)"

# --- VICE ---
# SwiftLink: ACIA mode 1, NMI (irq 1), at $de00, on the third RS232 device
x64sc \
	-logfile "$LOG_DIR/vice.log" \
	+remotemonitor \
	-kernal "$KERNAL" \
	-basic "$BASIC" \
	-chargen "$CHARGEN" \
	-acia1 \
	-acia1mode 1 \
	-acia1irq 1 \
	-acia1base 0xde00 \
	-myaciadev 2 \
	-userportdevice 0 \
	-rsdev3 "127.0.0.1:$MODEM_PORT" \
	-rsdev3ip232 \
	-rsdev3baud "$BAUD" \
	-drive8type 1541 \
	-dos1541 "$DOS1541" \
	-drive10type 0 \
	-drive11type 0 \
	-8 "$WORK_D64" \
	-keybuf "load\"$CCGMS_PRG\",8\nrun\n"
