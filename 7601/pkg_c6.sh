#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

if [ -z "$1" -o x"$1" = x"on" ]; then
	set -x
	msr_setbit A A 0xC0010292 32 1
elif [ x"$1" = x"off" ]; then
	msr_setbit A A 0xC0010292 32 0
fi

exit 0
