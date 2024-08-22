#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../physram.sh"
source "${CWD}/../msr.sh"

# reset uncore ratio
msr_write 0 0 0x620 0x00 0x0428

# turbo disable: NO
msr_setbit 0 A 0x1a0 38 0

( set -x; ${CWD}/ctdp_level.sh high )
( set -x; ${CWD}/pp_balance.sh policy_set 31 31 )

ntdrvldr_remove

exit 0