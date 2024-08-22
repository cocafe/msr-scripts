#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

# bash ${CWD}/balance.sh

# UNCORE RATIO
msr_write 0 0 0x00000620 0x00000000 0x00001c1c
msr_write 1 0 0x00000620 0x00000000 0x00001c1c

exit 0