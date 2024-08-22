#!/bin/bash

GUID_SUB_DISK="SUB_DISK"
GUID_DISKIDLE="DISKIDLE"

GUID_SUB_CPU="SUB_PROCESSOR"
GUID_MINCPU="PROCTHROTTLEMIN"
GUID_MAXCPU="PROCTHROTTLEMAX"

SCHEME_BALANCED=`powercfg /aliases | grep SCHEME_BALANCED | awk '{printf $1}'`
SCHEME_PS=`powercfg /aliases | grep SCHEME_MAX | awk '{printf $1}'`
SCHEME_PERF=`powercfg /aliases | grep SCHEME_MIN | awk '{printf $1}'`
SCHEME_CURRENT=`powercfg /getactivescheme | awk '{printf $3}'`

SCHEME_SILENT=64a64f24-65b9-4b56-befd-5ec1eaced9b3
SCHEME_TURBO=6fecc5ae-f350-48a5-b669-b472cb895ccf
SCHEME_PERFORMANCE=27fa6203-3987-4dcc-918d-748559d549ec

SCHEMES=( "${SCHEME_BALANCED}" "${SCHEME_SILENT}" "${SCHEME_TURBO}" "${SCHEME_PERFORMANCE}" )

for i in ${!SCHEMES[@]}; do
	(set -x; powercfg /setacvalueindex ${SCHEMES[$i]} ${GUID_SUB_CPU} ${GUID_MINCPU} 0)
	(set -x; powercfg /setacvalueindex ${SCHEMES[$i]} ${GUID_SUB_CPU} ${GUID_MAXCPU} 100)
done

(set -x; powercfg /setactive scheme_current)
