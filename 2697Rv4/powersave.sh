#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

# UNCORE RATIO
msr_write 0 0 0x00000620 0x00000000 0x00000c0c
msr_write 1 0 0x00000620 0x00000000 0x00000c0c

# POWER CTL
msr_setbit 0 0 0x000001fc 18 1
msr_setbit 1 0 0x000001fc 18 1

# PERFORMANCE BIAS
msr_write 0 A 0x000001b0 0x00000000 0x0000000F
msr_write 1 A 0x000001b0 0x00000000 0x0000000F

# C-STATE AUTOCONV
msr_write 0 A 0X000000e2 0x00000000 0x00010407
msr_write 1 A 0X000000e2 0x00000000 0x00010407

exit 0