#!/bin/bash

# set -x

GUID_SUB_DISK="SUB_DISK"
GUID_DISKIDLE="DISKIDLE"

GUID_SUB_CPU="SUB_PROCESSOR"
GUID_MINCPU="PROCTHROTTLEMIN"
GUID_MAXCPU="PROCTHROTTLEMAX"

GUID_SCHEME_BALANCED=`powercfg /aliases | grep SCHEME_BALANCED | awk '{printf $1}'`
GUID_SCHEME_PS=`powercfg /aliases | grep SCHEME_MAX | awk '{printf $1}'`
GUID_SCHEME_PERF=`powercfg /aliases | grep SCHEME_MIN | awk '{printf $1}'`
GUID_SCHEME_CURRENT=`powercfg /getactivescheme | awk '{printf $3}'`

if [ ${GUID_SCHEME_CURRENT} != ${GUID_SCHEME_BALANCED} ]; then
	echo "current power scheme is not BALANCED"
	exit 1
fi

set -x

powercfg /setacvalueindex SCHEME_BALANCED ${GUID_SUB_CPU} ${GUID_MINCPU} 0
powercfg /setacvalueindex SCHEME_BALANCED ${GUID_SUB_CPU} ${GUID_MAXCPU} 100
powercfg /setacvalueindex SCHEME_BALANCED ${GUID_SUB_DISK} ${GUID_DISKIDLE} 300	# 300s
powercfg /setactive scheme_current