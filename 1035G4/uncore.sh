#!/bin/bash

export PATH=$PATH:/cygdrive/c/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

msr_write 0 0 0x620 0x00 0x2323

exit 0