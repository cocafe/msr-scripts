#!/bin/bash

# set -x

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

bash ${CWD}/balance.sh

# UNCORE RATIO
msr_write 0 0 0x00000620 0x00000000 0x00001c1c
msr_write 1 0 0x00000620 0x00000000 0x00001c1c

# C-STATE DISABLED
# NOTE: disable C3/C6 reporting in BIOS first
msr_write 0 A 0X000000e2 0x00000000 0x00000000
msr_write 1 A 0X000000e2 0x00000000 0x00000000

exit 0