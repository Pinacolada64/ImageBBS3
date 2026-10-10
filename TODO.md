# TODO list

- Improve loading time of sub.* modules at startup. The normal call to load a sub.* file pushes the file on a "module stack," and when the newly-loaded sub.* file is done, it is popped off the stack, reloading the sub.* file previously in RAM. In the case of a few sub.* files, I don't think it is necessary to reload the previous file. I think by changing the line used (`im 110` is looking like the best candiate for testing) it will improve startup performance.

- Move RTC read/set methods in `sub.clocks` or some such similarly-named module. Add a i.IM/RTC module that uses this. I could add a method for reading/setting via the Dallas Semiconductor RTC which is emulated in VICE.
  - [x] `core/sub.clocks.lbl`, including the DS12C887 (see the follow-ups below)
  - [ ] the i.IM/RTC module

- fix directory sorting in i/MM.ud-sort (if the directory uses structs)

- move copies of file reader/directory functions in i.SF, i.CP.v3.1, who knows where else, into `sub.sysdos`

## SETUP: `i/su.config` redesign

Goal: a more organized setup, where you don't have to remember which drives
are online. Much of this may carry over to Image 128: see also
[Image-128 issue #1](https://github.com/Pinacolada64/Image-128/issues/1),
"Create a more comprehensive sysop setup experience", whose ideas are
included below.

> **Ordering matters:** `i/su.config` loads `sub.*` modules from Image
> drive 5, which a new setup doesn't assign until Part III. So set up the
> drives first: then modules (`sub.sysdos`, `sub.clocks`) can be used during
> setup.

### 1. Setup flow

- [ ] **Menu-driven setup** (`TODO: make menu-driven` in the code): a main
  menu of the parts, each marked ✓ when done, which can be revisited; a
  review screen before any files are written.
- [ ] The highlight bar routine from `i.t`'s phone book might be good for
  these menus (or "`++ 2`").
- [ ] Today, a wrong answer can't be corrected without rebooting. Say "You
  can change answers later" (and where: `IM`); perhaps use IM's menus to ask
  the questions in the first place.
- [ ] **Reorder the parts:** Drives → Clock → Sysop → BBS information.
- [ ] **Yes/No confirmations** for the Convert option and option 4.
- [ ] **"Hit Esc to retry"** when `d.data` isn't found (code TODO).
- [ ] **Safer 2.0 conversion:** confirm before scratching `e.loginmods`,
  `e.maintmods`, `e.menu*` and `d.GF*` (code FIXME).

### 2. Drives (Part III)

- [ ] **A numbered menu** instead of asking every question, then
  "Is the above information correct (Y/N)?" and starting over on No:

  ```
  1) System Disk......:  8,0
  2) E-Mail Disk......:  8,0
  3) Etcetera Disk....:  8,0
  4) Directory Disk...:  8,0
  5) Modules Disk.....:  9,0
  6) User Disk........: 10,0

  Enter the number to change, or hit Return if the above information is correct:
  ```

- [ ] **Scan the bus first**, as TADA's drive picker does: check devices
  8-30 with `open 15,d,15:close 15:if st` (the check `im` line 353 and
  `sub.clocks` use), and list what's online, so a drive can be picked from
  the list instead of typed from memory.
  - [ ] Optionally name each drive's model with an `M-R` of its ROM, as
    TADA's `drive_id.asm` does: `$E5BB` (1541/1571), `$A6DF` (1581). CMD
    drives and SD2IEC need another way (their status message?).
- [ ] **`$` at a Device/Drive prompt:** show a directory (`sub.sysdos`,
  `im=2`: pattern, block and file totals, "Another?").
- [ ] **`@` at a Device/Drive prompt:** send a DOS command (`sub.sysdos`,
  `im=1`), _e.g._ `cp3` to change CMD partition, `cd:` on SD2IEC. It already
  asks before `n` (format) or `s` (scratch).
- [ ] **Check each assignment:** the device is there, the drive/partition
  answers, and show its blocks free.
- [ ] `sub.sysdos` also loads from drive 5: assign that first, or load it
  from the boot device during setup.
- [ ] Ask whether a Lt. Kernal hard drive is used.
- [ ] Copy the system files to the chosen drives/partitions with
  `++ copier`.

### 3. Clock (Part II)

- [x] Choose any of the `sub.clocks` methods (manual, CMD, Lt. Kernal,
  DS12C887, Ultimate, TeensyROM, last AutoMaint date), including the
  DS12C887 at `$D500` that VICE emulates (Image-128 #1).
- [ ] Once the drives are known, try the chosen method with `sub.clocks` and
  show the time before going on.

### 4. Modem

- [ ] Set up the modem during setup: choose a `nimodem.dat` profile (_e.g._
  "tcpser (VICE)") or a telnet bridge.
- [ ] A configurable Hayes escape character, saved in `e.modem`.

### 5. BBS information (Part IV)

- [ ] **Ask for the BBS time zone during setup.** It isn't set now, so the
  time shows as "`<time> ^`" until the sysop sets it later (`tz$`, `e.data`
  record 45).
- [ ] **Time zone list: add `?=Re-list`.** There are about 15 time zones;
  with the screen mask on and the More prompt off, the list scrolls off the
  top of the screen and can't be shown again. (`sub.param2` also has a TODO
  for an `L=List` option for time zones.)
- [ ] Prime Time.
- [ ] Menus: text or graphic menu mode; lightbar options.
- [ ] Consider X-Tec's mod: e-mail address instead of phone number.
- [ ] Add user 1 (the sysop) to the QuickList (instant login).

### 6. Fixes

- [ ] Access group 9 is named "Group 10" (the loop variable + 1): it should
  be "Sysop" (code FIXME).
- [ ] Keep the copyright year in one place (code TODOs; "(c) 2019 NISSA BBS
  Software" around line 4266).
- [ ] Remove the old CMD/Lt. Kernal clock code (after `TODO: move "get time
  from cmd device" to sub.clocks`).
- [ ] **The sysop's screen height is wrong after setup:** on the first login
  to the sysop account, "More (Y/N)?" is asked after every line of a login
  file, as if the screen were 1 line high. Setup writes the user record's
  line length and screen height as one number, `40+24*256` (6184); find
  where login reads it back (`ll%` and `mp%`). `i/ED-pina-mod` has a TODO
  to "encode screen height/width like this: `ll%+mp%*256`", which suggests
  the reading side doesn't decode it that way yet.

### 7. Tidying

- [ ] One subroutine for the `Creating "<file>"...` / `Done!` messages.
- [ ] Log the setup messages to `e.log` (code TODO).
- [ ] Clear whole screen lines: can `&,69,0,<line>,"{40 spaces}"` do it? The
  screen line link needs clearing too.

### 8. Image 128

- [ ] Keep the bus scan and the `$`/`@` handling in `sub.*` modules, not in
  `i/su.config`, so a 128 version can share them.

## `sub.clocks` follow-ups

- [ ] **`Trc` right** ("Time: Reset Clock"), run every few hours by the
  default alarm trigger `At1`, re-reads the CMD RTC itself. Find where that's
  done and have it call `sub.clocks` (`im=0`: the method saved in `e.data`
  record 37) instead, so it works with every clock method.
- [ ] **`im` at boot:** set the clock with `sub.clocks` (`im=0`) instead of
  lines 3155-3156 and 3348-3366 (needs `core/im.lbl` to build first).
- [ ] **`i.IM` K (Set Time):** use `sub.clocks` (`im=1` manual, or "set from
  clock now").
- [ ] Remove the old CMD/Lt. Kernal clock code in `i/su.config` and `im`.

## Improving Image BBS

Gathered from the TODO/FIXME comments in this repo, the 1.2/2.0 repo
([ImageBBS](https://github.com/Pinacolada64/ImageBBS)) and
[Image-128](https://github.com/Pinacolada64/Image-128) (2026-10-09). The
2.0 repo's `v2/core` modules are mostly older copies of the 3.0 ones, so
only items not already here are listed from it. Locations are
`file:line` at the time of writing.

### Bugs

- [ ] `i.t`: file transfers broken ("loads screen mask, but does not transmit
  anything"); hanging up doesn't fix it (`core/i_t.lbl:12`, `:519`).
- [ ] `im`: on an error, a `goto` lands in the middle of a `for...next` loop
  (`core/im.lbl:717`).
- [ ] `i.SB`: line 3248 jumps to a line 3384 that doesn't exist; the `SG`
  case is already handled by 3242 (`core/i.SB.lbl:227`).
- [ ] `i/ED-pina-mod`: a handle is always reported as used by DE23, because
  `gosub 546` overwrites `i` and `a%` (`core/i_ED-pina-mod.lbl:396`).
- [ ] Weekday calculation "returns wrong day in many situations"
  (`core/tests/test-day-of-week.lbl:25`).
- [ ] `+.lo` (2.0): occasional `?illegal quantity` at 3488; linefeeds
  assumed after a failed login (ImageBBS issue #41)
  (`v2/core/plus_lo.lbl:4`, `:536`).
- [ ] ML: "is this a bug? should it be lda?" (`source/mcicm.s:173`);
  strings and cursor left/right (`asm/read.asm:2`).
- [ ] 1.2 ML: a jump into the middle of an instruction
  (`v1.2/source/ml-1_2-y2k.asm:5719`).
- [ ] SwiftLink: a spurious interrupt when DTR is toggled; VICE has an
  RS-232 interrupt pending at startup (`v2/asm/rs232/rs232-swift.asm:139`,
  `:262`).
- [ ] `i/IM.misc`: allow colour `0` to be entered; show the colours in two
  columns (`core/i_IM.misc.lbl:18`, `:23`).
- [ ] `i/MM.subop`: increment both BAR records whether writing or appending
  (`core/i_MM.subop.lbl:15`).

### Shared routines (less copy-and-paste)

- [ ] Open a SEQ file to write, or append if it exists (`,s,w` / `,s,a`),
  as one `im` routine (`core/im.lbl:85`, `:106`, `:115`).
- [ ] "Press any key" (`core/i.CP.lbl:176`); Yes/No with a chosen default
  instead of separate `gosub 93`/`95` (`im 128.bas:96`).
- [ ] `Creating "<file>"...` / `Done!` (`core/i_su.config.lbl:94`).
- [ ] Blocks free display (`core/i_lo.idle.lbl:109`).
- [ ] The copyright date in one place (`core/i_su.config.lbl:65`, `:193`,
  `:232`).
- [ ] Clear a whole screen line with `&,69` (`core/i_su.config.lbl:10`,
  `im 128.bas:448`, `:537`).
- [ ] Input with `w$` instead of shuffling `a$` (`core/im.lbl:74`).

### Dead or duplicate code

- [ ] `i/lo.idle`: duplicate of 4042, orphaned code, duplicate writes
  (`core/i_lo.idle.lbl:6`, `:22`, `:28`).
- [ ] `sub.editor`: an unreferenced line (`core/sub.editor.lbl:115`).
- [ ] `sub.display`: code also in `i/lo.on`; remove it from there
  (`core/sub.display.lbl:166`).
- [ ] `im`: two lines that repeat each other (`core/im.lbl:307`); 4050 is
  never called (`:818`); 2.0's `im.screens` is unreferenced
  (`v2/core/im.lbl:720`).
- [ ] `i.SB`: the duplicate `SG` handler (above), and code moved from
  `sub.comm2` (`core/i.SB.lbl:421`).

### Speed

- [ ] Load `sub.*` modules through `im` line 110 at boot, so the previous
  module isn't reloaded (see the first item at the top;
  `core/im.lbl:208`).
- [ ] ML: swap each module in separately (`source/intro.s:24`, also in
  Image-128).
- [ ] `&,14,2` instead of a `for...next` loop (`core/im.lbl:826`).
- [ ] Small ML clean-ups: `source/modem.s:124`, `source/irqhn.s:607`,
  `source/struct.s:112`, `source/ecs.s:460`.

### Features

- [ ] `i/ED-pina-mod` (user editor) (`core/i_ED-pina-mod.lbl`):
  - [ ] back up/restore the user file to a SEQ file (`:37`);
  - [ ] the weed info routines from 2.0's `+.ED` (`:9`);
  - [ ] X-Tec: a module to check the user file's data (`:41`);
  - [ ] act on a user number after `ED` (`:184`);
  - [ ] access group flags from `e.access` (`:400`); the protocols from
    `s.m.protos` (`:280`, `:383`);
  - [ ] update the alphabetical handle index when a handle changes
    (`:514`, `:516`).
- [ ] Login: only allow the options the user has access to
  (`core/i_lo.login.lbl:84`); re-add the `e.idlecmds` feature, and a
  lightbar check to turn off the extra login questions
  (`v2/core/plus_lo.lbl:12`, `:196`).
- [ ] Clocks: a uIEC's CMD-compatible clock (`v2/core/plusslashIM_time.lbl:110`).
  If it answers `t-ra`, `sub.clocks`' CMD method may already work.
- [ ] `i.t`: graphics mode/translation flags for each phone book entry
  (`core/i_t.lbl:14`).
- [ ] SwiftLink/Turbo232 auto-detect (`v2/asm/rs232/rs232.asm:10`).
- [ ] `sdp`: a device/drive prompt (`asm/sdp900705.lbl:9`).
- [ ] Buy a call with credits (`v2/core/plusslashlo_on.lbl:39`).
- [ ] From the 1.2 repo's issues: Zmodem/Ymodem (#51), an archive unpacker
  inside the BBS (#22), VF watchdog files (#12), the BRK handler (#9).

### Image 128

These belong in Image-128 (`im 128.bas`), with the setup ideas in its
issue #1:

- [ ] BASIC 7.0: `WINDOW` (`:484`), `DCLOSE` to close files (`:279`, `:281`).
- [ ] Move the modem setup and other setup lines into an `i/setup 128`
  (`:348`, `:550`).
- [ ] The RS-232 buffers (`:295`); check the `Dbg` lightbar before turning
  the border red (`:577`).
- [ ] Reorganize `im`'s line numbers for the 128 (`core/3_0-preface.lbl:25`,
  `:43`, `:87`).

### Docs

About 100 TODOs, mostly unfinished sections:

- [ ] `docs/prg-ampersand-calls.adoc` (22), including the empty `&,34`,
  `&,35`, `&,36`, `&,55`, `&,56` and `&,63` sections.
- [ ] `docs/setting-up.adoc` (16), `docs/im-configuration.adoc` (the IM
  sections still marked TODO), `docs/toc-mockup.adoc`.
- [ ] The 1.2 sysop manual's own list (`v1.2/docs/TODO`): tables,
  screenshots, a command summary, the CMD Mods chapter.

### Tools

- [ ] 2.0 `v2/asm/Makefile`: filename conversion (`ml_rs232.prg` →
  `ml.rs232`), disk directory timestamps.
- [ ] `scripts/c64list-linter.sh` (1.2 repo): lowercase keywords.
