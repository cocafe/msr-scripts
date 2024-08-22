#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

# C-STATE AUTOCONV
# C1/C3 UNDEMOTION
# DISABLE MWAIT CONV
msr_setbit 0 A 0xe2 16 1
msr_setbit 0 A 0xe2 27 1
msr_setbit 0 A 0xe2 28 1
msr_setbit 1 A 0xe2 16 1
msr_setbit 1 A 0xe2 27 1
msr_setbit 1 A 0xe2 28 1

exit 0
