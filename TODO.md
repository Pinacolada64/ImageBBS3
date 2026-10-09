# TODO list

- Improve loading time of sub.* modules at startup. The normal call to load a sub.* file pushes the file on a "module stack," and when the newly-loaded sub.* file is done, it is popped off the stack, reloading the sub.* file previously in RAM. In the case of a few sub.* files, I don't think it is necessary to reload the previous file. I think by changing the line used (`im 110` is looking like the best candiate for testing) it will improve startup performance.

- Move RTC read/set methods in `sub.clocks` or some such similarly-named module. Add a i.IM/RTC module that uses this. I could add a method for reading/setting via the Dallas Semiconductor RTC which is emulated in VICE.

- fix directory sorting in i/MM.ud-sort (if the directory uses structs)

- move copies of file reader/directory functions in i.SF, i.CP.v3.1, who knows where else, into `sub.sysdos`

SETUP
=====

- There was a routine to create a highlight bar in the phonebook for i.t; that might be cool to use in the BBS setup program.

- A more comprehensive & user-friendly setup process: instead of typing in options like:

.. System Disk Device?
.. System Disk Drive?

Is the above information correct (Y/N)? [Yes]

...and restarting all the questions if you say No, present a numbered menu:

1) System Disk......:  8,0
2) E-Mail Disk......:  8,0
3) Etcetera Disk....:  8,0
4) Directory Disk...:  8,0
5) Modules Disk.....:  9,0
6) User Disk........: 10,0

Enter the number to change, or hit Return if the above information is correct:

- can &,69,0,<line>,"{40 spaces}" be used to properly clear a screen line? need to clear line link too
