#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

msr_setbit 0 A 0xe2 30 1
msr_rmw 0 A 0xe2 7 0 0x07
msr_setbit 1 A 0xe2 30 1
msr_rmw 1 A 0xe2 7 0 0x07

exit 0
