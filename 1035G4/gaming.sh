#!/bin/bash

export PATH=$PATH:/cygdrive/c/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

# C-STATE AUTOCONV
# C1/C3 UNDEMOTION
# DISABLE MWAIT CONV
# msr_write 0 A 0x000001fc 0x00000000 0x18010000

msr_write 0 0 0x620 0x00 0x2323

# Turbo DISABLE: YES
msr_setbit 0 A 0x1a0 38 1

# BDPROCHOT: DISABLE
msr_setbit 0 A 0x1fc 0 0

# Thermal Control Circuit: DISABLE
msr_setbit 0 A 0x1a0 3 0

exit 0