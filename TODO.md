# TODO list

- Improve loading time of sub.* modules at startup. The normal call to load a sub.* file pushes the file on a "module stack," and when the newly-loaded sub.* file is done, it is popped off the stack, reloading the sub.* file previously in RAM. In the case of a few sub.* files, I don't think it is necessary to reload the previous file. I think by changing the line used (`im 110` is looking like the best candiate for testing) it will improve startup performance.

- Move RTC read/set methods in `sub.clocks` or some such similarly-named module. Add a i.IM/RTC module that uses this. I could add a method for reading/setting via the Dallas Semiconductor RTC which is emulated in VICE.
  - [x] `core/sub.clocks.lbl`, including the DS12C887 (see the follow-ups below)
  - [ ] the i.IM/RTC module

- fix directory sorting in i/MM.ud-sort (if the directory uses structs)

- move copies of file reader/directory functions in i.SF, i.CP.v3.1, who knows where else, into `sub.sysdos`

## SETUP: `i/su.config` redesign

Goal: a more organized setup, where you don't have to remember which drives
are online. Much of this may carry over to Image 128.

> **Ordering matters:** `i/su.config` loads `sub.*` modules from Image
> drive 5, which a new setup doesn't assign until Part III. So set up the
> drives first: then modules (`sub.sysdos`, `sub.clocks`) can be used during
> setup.

### 1. Setup flow

- [ ] **Menu-driven setup** (`TODO: make menu-driven` in the code): a main
  menu of the parts, each marked ✓ when done, which can be revisited; a
  review screen before any files are written.
- [ ] The highlight bar routine from `i.t`'s phone book might be good for
  these menus.
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

### 3. Clock (Part II)

- [x] Choose any of the `sub.clocks` methods (manual, CMD, Lt. Kernal,
  DS12C887, Ultimate, TeensyROM, last AutoMaint date).
- [ ] Once the drives are known, try the chosen method with `sub.clocks` and
  show the time before going on.

### 4. Fixes

- [ ] Access group 9 is named "Group 10" (the loop variable + 1): it should
  be "Sysop" (code FIXME).
- [ ] Keep the copyright year in one place (code TODOs; "(c) 2019 NISSA BBS
  Software" around line 4266).
- [ ] Remove the old CMD/Lt. Kernal clock code (after `TODO: move "get time
  from cmd device" to sub.clocks`).

### 5. Tidying

- [ ] One subroutine for the `Creating "<file>"...` / `Done!` messages.
- [ ] Log the setup messages to `e.log` (code TODO).
- [ ] Clear whole screen lines: can `&,69,0,<line>,"{40 spaces}"` do it? The
  screen line link needs clearing too.

### 6. Image 128

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
