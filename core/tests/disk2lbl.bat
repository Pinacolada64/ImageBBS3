@echo off
set oldpath=%PATH%
echo Before: %PATH%
set path=%PATH%D:\Documents\C64\GTK3VICE-3.4-win64-r38882\GTK3VICE-3.4-win64-r38882\bin
echo After: %PATH%

rem clean up *.prg files
for %%f in (*.prg) do del "%%f"

rem extract all files from master disk
c1541.exe "MASTER D1 200905.D81" -extract

rem add .prg extension: rename current_name new_name.prg
for %%f in (i.* i_* sub.*) do rename "%%f" "%%f.prg"

rem convert i.*.prg, i_*.prg files to i[./]*.lbl files
set path=%OLDPATH%D:\Documents\C64\
echo After: %PATH%

if not exist i.main.prg goto :EOF

echo Made it past path reassign.

rem get basename of %f, add .lbl extension:
for %%f in (*.prg) do c64list4_03.exe "%%f" -lbl:"%%~nf.lbl" -keycase -varcase -alpha:alt -crunch -ovr

:EOF
set path=%oldpath%
