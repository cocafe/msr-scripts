#!/bin/bash

export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin

source /cygdrive/d/Program/msr-watchdog/scripts/bitops.sh
source /cygdrive/d/Program/msr-watchdog/scripts/msr.sh

# set -x

# exec >> /cygdrive/r/v3_turbo_`date '+%Y-%m-%d_%H_%M_%S'`.log 2>&1

#
# HOW TO USE
#
# 1 remove microcode update in BIOS file and flash it to board
#   o v3x4 module is not required to insert into BIOS
#
# 2 recommended to disable c6 and package c-states (set to c0/c1) and enable c3
#   o some ucode removed motherboards may fail to boot into OS with any c-state
#     enabled, if so, disable them ALL, you are out of luck getting extra boost
#   o if cpu does not have c3 or c6 enabled, single core will not turbo over
#     the default maximum full load turbo ratio
#     e.g, by default 2699v3 full load on 2.8GHz turbo, if c-state disabled,
#     single core will not go over 2.8GHz, with c3 enabled, single core can
#     boost up to 3.6GHz. with turbo unlocked and c3 enabled, full load ratio
#     boosts to 3.4GHz from 3.2GHz, and csgo benchmark increased 40fps
#   o but notice, on V4, if c3/c6 enabled, score of single thread benchmark
#     like cpu-z may increase but gaming actually sucks with c-stated enabled
#     on V4, crappy and choppy. disable all c-states to get maximum fps on V4.
#
# 3 rename or delete microcode update provided by Windows using NSudo
#   C:\Windows\System32\mcupdate_GenuineIntel.dll
#
# 4 get or make microcode.dat and install vmware cpumcupdate kernel driver
#   o vmware cpumcupdate
#     https://labs.vmware.com/flings/vmware-cpu-microcode-update-driver
#   o dummy amd mc bin 
#     https://git.kernel.org/cgit/linux/kernel/git/firmware/linux-firmware.git/tree/amd-ucode
#   o get some microcode.dat
#     https://1drv.ms/f/s!AgP0NBEuAPQRpdoWT_3G3XCdotPmWQ
#     https://github.com/platomav/CPUMicrocodes
#   o more info about microcode.dat
#     https://onedrive.live.com/?authkey=%21AIlV3zL6AzTkzGk&cid=11F4002E1134F403&id=11F4002E1134F403%21643183&parId=11F4002E1134F403%21643182&o=OneUp
# 
# 5 set cpumcupdate to manually start (IMPORTANT!)
#   o regedit, goto [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\cpumcupdate]
#     o change value of [Start] to [0x03] which means manually
#
# 6 install cygwin64 and execute this script with 
#   windows task scheduler on startup and S3/S4 resume
#   o event to detect S3/S4 resume in task scheduler:
#     o log:    [SYSTEM]
#     o source  [Power-Troubleshooter]
#     o ID:     [1]
#   
#   what this script does:
#     o set turbo bin with bugged ucode version
#     o start vmware cpumcupdate to load new ucode
#
# NOTE: new ucode is likely to improve performace in some cases that's
# why this script is struggling to make new ucode works without inserting v3x4.
# but some motherbaords may fail to resume from S4 (hibernate) state
# with ucode REMOVED in BIOS and NEWER ucode LOADED in OS. if so,
# you may be out of luck, just set turbo bin and run without new ucode.
#

# MSR_CMD=/cygdrive/d/Program/msr-watchdog/msr-cmd.exe
# __msr_write()
# {
#   local pkg=$1
#   local cpu=$2
#   local reg=$3
#   local edx=$4
#   local eax=$5
#
#   if [ $# -ne 5 ]; then
#     echo "invalid parameters: $@"
#     echo "press any key to exit..."
#     read
#     exit -1
#   fi
#
#   echo "msr write: $@"
#
#   if [ "$cpu" = "A" -o "$cpu" = "ALL" ]; then
#     ${MSR_CMD} -g $pkg -a -s write $reg $edx $eax
#   else
#     ${MSR_CMD} -g $pkg -p $cpu -s write $reg $edx $eax
#   fi
#
#   if [ $? -ne 0 ]; then
#     echo "write msr failed: $@"
#     echo "press any key to exit..."
#     read
#     exit -1
#   fi
# }

echo "V3 TURBO"

# sleep 3

sc query cpumcupdate 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "cpumcupdate service is not installed"
  exit 1
fi

echo "cpumcupdate service is installed"

sc query cpumcupdate | grep STATE | grep -q STOPPED
if [ $? -ne 0 ]; then
  echo "cpumcupdate service is not stopped"
  read
  exit 1
fi

echo "cpumcupdate service is stopped"

MCU=$(msr_read 0 0 0x8b | awk '{print $4}')
if [ $? -ne 0 ]; then
  echo "failed to read microcode version msr"
  read
  exit 1
fi

if [ "$MCU" != "0x00000000" ]; then
  echo "cpu is patched, abort"
  read
  exit 1
fi

# UNCORE RATIO
msr_write 0 0 0x00000620 0x00000000 0x00001e1e
msr_write 1 0 0x00000620 0x00000000 0x00001e1e

# DISABLE C-STATE
# msr_write 0 A 0x000000e2 0x00000000 0x00000000
# msr_write 1 A 0x000000e2 0x00000000 0x00000000

# UNLIMIT PL1/PL2
msr_write 0 0 0x00000610 0x8007ffff 0x00ffffff
msr_write 1 0 0x00000610 0x8007ffff 0x00ffffff

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

# UNLOCK TURBO BIN
msr_write A 0 0x000001ad 0x24242424 0x24242424
msr_write A 0 0x000001ae 0x24242424 0x24242424
msr_write A 0 0x000001af 0x80000000 0x00002424

#
# NOTE: set voltage after loading NEWER ucode will RESET turbo bin
#

NEGATIVE_100mV=0xf3400000
NEGATIVE_98mV=0xf3800000
NEGATIVE_95mV=0xf3e00000
NEGATIVE_90mV=0xf4800000
NEGATIVE_85mV=0xf5200000
NEGATIVE_80mV=0xf5c00000
NEGATIVE_75mV=0xf6800000
NEGATIVE_70mV=0xf7000000
NEGATIVE_65mV=0xf7a00000
NEGATIVE_60mV=0xf8600000
NEGATIVE_50mV=0xf9a00000
NEGATIVE_25mV=0xfcd00000
NEGATIVE_20mV=0xfd800000
NEGATIVE_10mV=0xfec00000
DEFAULT_0mV=0x00000000

# FIVR Faults: Disable
# msr_write A 0 0x00000150 0x80000015 0x00000001

# FIVR Efficiency Mode: Disable
# msr_write A 0 0x00000150 0x80000015 0x00000002

# IA CORE
msr_write A 0 0x00000150 0x80000011 ${NEGATIVE_60mV}

# UNCORE
msr_write A 0 0x00000150 0x80000211 ${NEGATIVE_50mV}

# SYSTEM AGENT
msr_write A 0 0x00000150 0x80000311 ${DEFAULT_0mV}

# OC LOCK: Volt and TurboBin Locked
# msr_setbit 0 0 0x00000194 20 1
# msr_setbit 1 0 0x00000194 20 1

echo "cpumcupdate service is starting"

sc start cpumcupdate
sc query cpumcupdate | grep STATE | grep -q RUNNING
if [ $? -ne 0 ]; then
  echo "failed to start cpumcupdate"
  exit 1
fi

sc stop cpumcupdate
sc query cpumcupdate | grep STATE | grep -q STOPPED
if [ $? -ne 0 ]; then
  echo "failed to stop cpumcupdate"
  exit 1
fi

MCU=$(msr_read 0 0 0x8b | awk '{print $3}')
if [ $? -eq 0 ]; then
  echo "patched microcode: $MCU"
fi

echo "done"

sleep 2

exit 0