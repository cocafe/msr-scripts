#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"

source "${CWD}/reg.sh"
source "${CWD}/../bitops.sh"
source "${CWD}/../physram.sh"

# default:
# PP0 IA: 9
# PP1 GT: 13

MAXVAL=`genmask32 4 0`

policy_get()
{
  local pp0=`mmio_read ${MMIO_PP0_POLICY_WIDTH} ${MMIO_PP0_POLICY}`
  local pp1=`mmio_read ${MMIO_PP1_POLICY_WIDTH} ${MMIO_PP1_POLICY}`

  echo "IA: $(($pp0 & `genmask32 4 0`)) GT: $(($pp1 & `genmask32 4 0`))"
}

policy_set()
{
  local pp0=$1
  local pp1=$2

  if [ x"$1" = x"" -o x"$2" = x"" ]; then
    echo "invalid args"
    exit 1
  fi

  if [ $pp0 -gt $(($MAXVAL)) ]; then
    pp0=${MAXVAL}
  fi

  if [ $pp1 -gt $(($MAXVAL)) ]; then
    pp1=${MAXVAL}
  fi

  pp0=`tohex $pp0`
  pp1=`tohex $pp1`

  mmio_write ${MMIO_PP0_POLICY_WIDTH} ${MMIO_PP0_POLICY} $pp0
  mmio_write ${MMIO_PP1_POLICY_WIDTH} ${MMIO_PP1_POLICY} $pp1
}

if [ x"$1" = x"" ]; then
  echo "policy_get"
  echo "policy_set <IA> <GT>"
  exit 1
fi

CMD=$1

shift 

$CMD $@