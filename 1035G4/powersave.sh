#!/bin/bash

export PATH=$PATH:/cygdrive/c/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

# C-STATE AUTOCONV
# C1/C3 UNDEMOTION
# DISABLE MWAIT CONV
# msr_write 0 A 0x000001fc 0x00000000 0x18010000

msr_write 0 0 0x620 0x00 0x0423

# Turbo DISABLE: YES
msr_setbit 0 A 0x1a0 38 1

exit 0