#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

MSR_CMD=/cygdrive/d/Program/msr-watchdog/msr-cmd.exe

# set -x

msr_write()
{
  local pkg=$1
  local cpu=$2
  local reg=$3
  local edx=$4
  local eax=$5

  if [ $# -ne 5 ]; then
    echo "invalid parameters: $@"
    echo "press any key to exit..."
    read
    exit -1
  fi

  echo "msr write: $@"

  if [ "$cpu" = "A" -o "$cpu" = "ALL" ]; then
    ${MSR_CMD} -g $pkg -a -s write $reg $edx $eax
  else
    ${MSR_CMD} -g $pkg -p $cpu -s write $reg $edx $eax
  fi

  if [ $? -ne 0 ]; then
    echo "write msr failed: $@"
    echo "press any key to exit..."
    read
    exit -1
  fi
}

# UNCORE RATIO
msr_write 0 0 0x00000620 0x00000000 0x00000c1c
msr_write 1 0 0x00000620 0x00000000 0x00000c1c

# PERFORMANCE BIAS
msr_write 0 A 0x000001b0 0x00000000 0x00000000
msr_write 1 A 0x000001b0 0x00000000 0x00000000

exit 0