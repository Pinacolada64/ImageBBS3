# VICE start scripts

Copies of the scripts used to run Image BBS 3.0 in VICE, kept here at a
known-good baseline. The working copies live in `~/bin`.

| Script | What it runs |
|---|---|
| `start-image-bbs.sh` | Image BBS 3.0 in VICE (x64sc): two 1581 drives (10 = programs, 11 = data), an emulated SwiftLink, and `tcpser` as the modem (callers telnet to port 6400) |
| `start-ccgms.sh` | The CCGMS 2021 terminal program in a second VICE, with its own `tcpser`, to call the BBS: `atdt127.0.0.1:6400` |

Both expect VICE 3.8 (`x64sc`), `tcpser` in `~/bin/tcpser/`, and the
JiffyDOS ROMs in `~/Documents/c64/JiffyDOS/`; the paths are set at the top
of each script. See the comments in each script for the options
(`TCPSER_TRACE`, `TCPSER_LOG_LEVEL`, `TCPSER_INVERT_DCD`, and `RTC` for the
BBS's DS12C887 real-time clock cartridge at `$D500`).

Wait for the BBS's idle screen before dialing: a call that arrives while
`sub.modem` is still setting up the modem (after boot, and after each call)
is hung up by the setup's `ATH0`.
