#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"

source "${CWD}/reg.sh"
source "${CWD}/../bitops.sh"
source "${CWD}/../physram.sh"

default_ctdp()
{
  mmio_write ${MMIO_CTDP_CTRL_WIDTH} ${MMIO_CTDP_CTRL} 0x0
}

high_ctdp()
{
  mmio_write ${MMIO_CTDP_CTRL_WIDTH} ${MMIO_CTDP_CTRL} 0x2
}

low_ctdp()
{
  mmio_write ${MMIO_CTDP_CTRL_WIDTH} ${MMIO_CTDP_CTRL} 0x1
}

if [ x"$1" = x"" ]; then
  echo "<default/low/high>"
  exit 1
fi

$1_ctdp
