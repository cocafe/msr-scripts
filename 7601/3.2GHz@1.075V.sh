#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

/cygdrive/d/Program/msr-watchdog/scripts/7601/zenstates_win.py --enable -p 0 --did 2 --ratio 32 --vcore 1.075 --c6-disable
/cygdrive/d/Program/msr-watchdog/scripts/7601/zenstates_win.py --list
