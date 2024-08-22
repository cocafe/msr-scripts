#!/bin/bash

MSR_PKG_PWR=0x610

# turbo activation ratio
MSR_TURBO_ACTRTO=0x64c

MCHBAR_BASE=0xfedc0000

mchbar_addr()
{
  local offset=$1
  printf 0x%08x $(( ${MCHBAR_BASE} + $offset ))
}

MMIO_PKG_PWR=`mchbar_addr 0x59a0`
MMIO_PKG_PWR_WIDTH=64

# IA domain
MMIO_PP0_POLICY=`mchbar_addr 0x5920`
MMIO_PP0_POLICY_WIDTH=32

# GT domain
MMIO_PP1_POLICY=`mchbar_addr 0x5924`
MMIO_PP1_POLICY_WIDTH=32

# system agent control
MMIO_SAPM_CTRL=`mchbar_addr 0x5f00`
MMIO_SAPM_CTRL_WIDTH=32

# default cTDP ratio
MMIO_CTDP_DEF=`mchbar_addr 0x5f3c`
MMIO_CTDP_DEF_WIDTH=32

# cTDP Level 1 (lower tdp)
MMIO_CTDP1=`mchbar_addr 0x5f40`
MMIO_CTDP1_WIDTH=64

# cTDP Level 2 (higher tdp)
MMIO_CTDP2=`mchbar_addr 0x5f48`
MMIO_CTDP2_WIDTH=64

# cTDP selection
# 31  lock
# 1:0 0: default 1: level1 2: level2
MMIO_CTDP_CTRL=`mchbar_addr 0x5f50`
MMIO_CTDP_CTRL_WIDTH=32
