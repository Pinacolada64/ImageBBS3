#!/usr/bin/env bash
# start-image-bbs.sh: run Image BBS 3.0 in VICE (x64sc), with tcpser as the modem
#
#   start-image-bbs.sh
#
# - tcpser emulates a Hayes modem: callers telnet to port $TELNET_PORT, and
#   VICE's emulated SwiftLink talks to tcpser on $MODEM_PORT (ip232, which
#   also carries the modem's DCD/DTR lines, so the BBS sees calls and can
#   hang up).
# - Two 1581 drives: device 10 = programs (boot disk), device 11 = data.
#   They are working copies in $RUN_DIR, made only if they don't exist yet:
#     programs.d81 <- ImageBBS3/build/image30-tests.d81 ("make test-disk":
#                     the release boot disk plus the test programs)
#     data.d81     <- Disk 2 of the 8-Bit Boyz release 231231
#   Delete one to start that disk over from its source.
# - tcpser is stopped when VICE exits.
# - The user port RS-232 is switched off (-userportdevice 0): vicerc may
#   connect it to the same device as the SwiftLink, and then the SwiftLink's
#   bytes never reach tcpser.
#
# Logs: $LOG_DIR/tcpser.log and $LOG_DIR/vice.log
#
# tcpser logging can be turned up for one run, e.g. to see the AT commands
# the BBS sends and tcpser's replies:
#   TCPSER_TRACE=sS start-image-bbs.sh
#   TCPSER_LOG_LEVEL   0 (none) - 7 (everything); default 4 (info)
#   TCPSER_TRACE       data to trace, any of: s = from the C64, S = to the C64,
#                      m/M = modem in/out, i/I = IP (caller) in/out
#   TCPSER_INVERT_DCD  1 (default) inverts DCD (tcpser -I), 0 doesn't

set -euo pipefail

# --- disks ---
REPO="$HOME/Documents/c64/ImageBBS3"
RUN_DIR="$HOME/Documents/c64/ImageBBS3-run"
PROGRAMS_D81="$RUN_DIR/programs.d81"
DATA_D81="$RUN_DIR/data.d81"
BUILD_D81="$REPO/build/image30-tests.d81"
RELEASE_ZIP="$HOME/Documents/c64/image30-231231.zip"
RELEASE_DATA="MASTER D2 231231.d81"

# --- modem (tcpser) ---
TCPSER="$HOME/bin/tcpser/tcpser"
MODEM_PORT=25238   # VICE <-> tcpser, on 127.0.0.1 only
TELNET_PORT=6400   # callers telnet here
# 19200: the fastest the current Image 3.0 RS-232 ML handles (a newer ML from
# Al DeRosa adds 56k); also IM's "tcpser (VICE)" modem profile
BAUD=19200
TCPSER_LOG_LEVEL=${TCPSER_LOG_LEVEL:-4}
TCPSER_TRACE=${TCPSER_TRACE:-}
# -I: invert DCD. Through VICE's SwiftLink, Image BBS otherwise sees a carrier
# (the check mark in the bottom-right corner) when nobody is connected.
TCPSER_INVERT_DCD=${TCPSER_INVERT_DCD:-1}

# --- ROMs ---
# JiffyDOS in both the C64 and the 1581s speeds up all the module loading
VICE_ROMS="$HOME/.local/share/vice/C64"
JIFFYDOS="$HOME/Documents/c64/JiffyDOS"
KERNAL="$JIFFYDOS/JDOS64.rom"
DOS1581="$JIFFYDOS/Jiffy1581.rom"
BASIC="$VICE_ROMS/basic-901226-01.bin"
CHARGEN="$VICE_ROMS/chargen-901225-01.bin"

LOG_DIR="$RUN_DIR/logs"

die() { echo "start-image-bbs: $*" >&2; exit 1; }

for f in "$TCPSER" "$KERNAL" "$DOS1581" "$BASIC" "$CHARGEN"; do
	[ -e "$f" ] || die "not found: $f"
done
command -v x64sc > /dev/null || die "x64sc (VICE) isn't on the PATH"

mkdir -p "$RUN_DIR" "$LOG_DIR"

# --- working copies of the disks ---
if [ ! -f "$PROGRAMS_D81" ]; then
	[ -f "$BUILD_D81" ] || die "$BUILD_D81 not found: run 'make test-disk' in $REPO first"
	cp "$BUILD_D81" "$PROGRAMS_D81"
	echo "Made $PROGRAMS_D81 from $BUILD_D81"
fi
if [ ! -f "$DATA_D81" ]; then
	[ -f "$RELEASE_ZIP" ] || die "$RELEASE_ZIP not found"
	unzip -p "$RELEASE_ZIP" "$RELEASE_DATA" > "$DATA_D81"
	echo "Made $DATA_D81 from $RELEASE_DATA"
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
echo "tcpser: callers telnet to port $TELNET_PORT (log: $LOG_DIR/tcpser.log)"

# --- VICE ---
# SwiftLink: ACIA mode 1, NMI (irq 1), on the third RS232 device (myaciadev 2)
x64sc \
	-logfile "$LOG_DIR/vice.log" \
	-kernal "$KERNAL" \
	-basic "$BASIC" \
	-chargen "$CHARGEN" \
	-acia1 \
	-acia1mode 1 \
	-acia1irq 1 \
	-myaciadev 2 \
	-userportdevice 0 \
	-rsdev3 "127.0.0.1:$MODEM_PORT" \
	-rsdev3ip232 \
	-rsdev3baud "$BAUD" \
	-drive8type 0 \
	-drive10type 1581 \
	-drive11type 1581 \
	-dos1581 "$DOS1581" \
	-10 "$PROGRAMS_D81" \
	-11 "$DATA_D81" \
	-keybuf 'load"boot 3.0",10,1\n'
