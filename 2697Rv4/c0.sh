#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

# bash ${CWD}/balance.sh

# NO C-STATE
msr_write 0 A 0x000000e2 0x00000000 0x00000000
msr_write 1 A 0x000000e2 0x00000000 0x00000000

exit 0
