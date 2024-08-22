#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

bash ${CWD}/balance.sh
bash ${CWD}/c6.sh
bash ${CWD}/pkg_c6.sh
bash ${CWD}/../powercfg_chk.sh

exit 0