#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

msr_write 0 0 0x620 0x00 0x2828

# Turbo DISABLE: YES
msr_setbit 0 A 0x1a0 38 1

exit 0