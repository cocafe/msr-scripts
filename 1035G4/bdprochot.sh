#!/bin/bash

export PATH=$PATH:/cygdrive/c/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

# BDPROCHOT: DISABLE
msr_setbit 0 A 0x1fc 0 0

# Thermal Control Circuit: DISABLE
msr_setbit 0 A 0x1a0 3 0

exit 0