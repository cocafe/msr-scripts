#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

CWD="$(dirname "$0")"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"

# UNCORE RATIO
msr_write 0 A 0x00000620 0x00000000 0x00000c1c
msr_write 1 0 0x00000620 0x00000000 0x00000c1c

# POWER CTL
# FAST_BRK: 0
msr_setbit 0 A 0x1fc 3 0
msr_setbit 1 0 0x1fc 3 0
msr_setbit 0 A 0x1fc 4 0
msr_setbit 1 0 0x1fc 4 0
# PHOLD_CST_PREVENT
msr_setbit 0 A 0x1fc 16 0
msr_setbit 1 0 0x1fc 16 0
# PHOLD_SR DISABLE
msr_setbit 0 A 0x1fc 17 1
msr_setbit 1 0 0x1fc 17 1
# ENABLE ENERGY_P-STATE (MSR 0x1b0 will be DISABLE) : 0
msr_setbit 0 A 0x1fc 18 0
msr_setbit 1 0 0x1fc 18 0
# DISABLE EE TURBO: 1
msr_setbit 0 A 0x1fc 19 1
msr_setbit 1 0 0x1fc 19 1
# DISABLE EE-P Control: 1
msr_setbit 0 A 0x1fc 23 1
msr_setbit 1 0 0x1fc 23 1
# DYN SWITCHING: 0
msr_setbit 0 A 0x1fc 24 0
msr_setbit 1 0 0x1fc 24 0
# LTR DISABLE: 1
msr_setbit 0 A 0x1fc 28 1
msr_setbit 1 0 0x1fc 28 1
msr_setbit 0 A 0x1fc 29 1
msr_setbit 1 0 0x1fc 29 1
# PKG C-STATE LAT NEG DISABLE: 1
msr_setbit 0 A 0x1fc 30 1
msr_setbit 1 0 0x1fc 30 1

# VR_CONFIG
# PKG C-STATE DECAY ENABLE: 0
# msr_setbit 0 0 0x603 52 0
# msr_setbit 1 0 0x603 52 0
# DYNAMIC LOAD LINE: 0 ohm
# msr_rmw 0 0 0x603 7  0  0x00
# msr_rmw 1 0 0x603 7  0  0x00
# msr_rmw 0 0 0x603 15 8  0x00
# msr_rmw 1 0 0x603 15 8  0x00
# msr_rmw 0 0 0x603 23 16 0x00
# msr_rmw 1 0 0x603 23 16 0x00
# IOUT OFFSET +6.25% IccMax
# msr_rmw 0 0 0x603 39 32 0x7f
# msr_rmw 1 0 0x603 39 32 0x7f
# IOUT SLOPE 1.0
# msr_rmw 0 0 0x603 49 40 0x00
# msr_rmw 1 0 0x603 49 40 0x00

# ENERGY/PERF BIAS: MAX PERFORMANCE
# msr_write 0 A 0x000001b0 0x00000000 0x00000000
# msr_write 1 A 0x000001b0 0x00000000 0x00000000

# C-STATE AUTOCONV
# C1/C3 UNDEMOTION
# DISABLE MWAIT CONV
msr_write 0 A 0X000000e2 0x00000000 0x18010000
msr_write 1 A 0X000000e2 0x00000000 0x18010000

# Turbo Activation Ratio for Legacy P-State
# default: 0x17
# for legacy p-state, threshold of ratio to treat as maximum p-state
msr_write 0 A 0x0000064c 0x00000000 0x00000014
msr_write 1 0 0x0000064c 0x00000000 0x00000014

exit 0