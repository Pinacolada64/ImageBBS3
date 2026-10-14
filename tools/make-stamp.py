#!/usr/bin/env python3
"""make-stamp.py: write source/stamp.s, the build's stamp for the ML.

    tools/make-stamp.py source/stamp.s

Run by the Makefile on every build of the ML. stamp.s defines:

  version_string    the first 8 characters of the git commit (&,5 returns it
                    in a$)
  version_revision  the revision, which &,5 returns in a%: the number of
                    commits since version_number last changed in
                    source/equat.s. The same commit always gets the same
                    revision; bumping the version starts it again at 0.
  build_weekday ... build_minute
                    the date and time of the build, in the ML's bootdate
                    format (BCD): the clock starts from them until it's set.
                    weekday 1-7 (1=Sunday); hour as the CIA clock and Image's
                    11-digit dates have it: 01-12, plus $80 for PM (12 AM is
                    $12, 12 PM is $92)
"""

import datetime
import subprocess
import sys


def git(*args):
    return subprocess.run(['git', *args], capture_output=True, text=True,
                          check=True).stdout.strip()


def bcd(n):
    return '$%02d' % n


def main():
    out = sys.argv[1]
    commit = git('log', '-1', '--format=%H')[:8]
    base = git('log', '-1', '--format=%H', '-G', r'^\.var version_number',
               '--', 'source/equat.s')
    revision = int(git('rev-list', '--count', base + '..HEAD')) if base else 0

    now = datetime.datetime.now()
    weekday = now.isoweekday() % 7 + 1          # Monday=1..Sunday=7 -> Sunday=1
    hour = now.hour % 12 or 12                  # 1-12
    hour_byte = '$%s%d' % ('9' if hour >= 10 else '8', hour % 10) \
        if now.hour >= 12 else bcd(hour)

    with open(out, 'w') as f:
        f.write('// written by tools/make-stamp.py: don\'t edit\n')
        f.write('.var version_string ="%s"\n' % commit)
        f.write('.var version_revision = %d\n' % revision)
        f.write('// built %s\n' % now.strftime('%a %b %d, %Y %I:%M %p'))
        f.write('.var build_weekday = %s\n' % bcd(weekday))
        f.write('.var build_month = %s\n' % bcd(now.month))
        f.write('.var build_date = %s\n' % bcd(now.day))
        f.write('.var build_year = %s\n' % bcd(now.year % 100))
        f.write('.var build_hour = %s\n' % hour_byte)
        f.write('.var build_minute = %s\n' % bcd(now.minute))


if __name__ == '__main__':
    main()
