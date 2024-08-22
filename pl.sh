#!/bin/bash

# set -x

export PATH=/cygdrive/d/Program/cygwin64/bin:$PATH

source /cygdrive/d/Program/msr-watchdog/scripts/bitops.sh
source /cygdrive/d/Program/msr-watchdog/scripts/msr.sh
source /cygdrive/d/Program/msr-watchdog/scripts/physram.sh

POWER_UNIT=
ENERGY_UNIT=
TIME_UNIT=

MSR_PL1=
MSR_PL1_CALC=
MSR_PL1_EN=
MSR_PL1_CLAMP=
MSR_PL1_TIMEWD=
MSR_PL1_TIMEWD_CALC=
MSR_PL2=
MSR_PL2_CALC=
MSR_PL2_EN=
MSR_PL2_CLAMP=
MSR_PL2_TIMEWD=
MSR_PL2_TIMEWD_CALC=
MSR_PL_LOCK=

MMIO_PL1=
MMIO_PL1_CALC=
MMIO_PL1_EN=
MMIO_PL1_CLAMP=
MMIO_PL1_TIMEWD=
MMIO_PL1_TIMEWD_CALC=
MMIO_PL2=
MMIO_PL2_CALC=
MMIO_PL2_EN=
MMIO_PL2_CLAMP=
MMIO_PL2_TIMEWD=
MMIO_PL2_TIMEWD_CALC=
MMIO_PL_LOCK=

__unit_get()
{
	local ret=`msr_read 0 0 0x606`
	local val=

	if [ $? -ne 0 ]; then
		exit 1
	fi

	val=`echo $ret | awk '{print $5}' | tr -d '\r'`

	# 3:0
	POWER_UNIT=$(( ($val & `genmask32 3 0`) >> 0 ))
	POWER_UNIT=`bc -l <<< "1 / (2 ^ ${POWER_UNIT})"`
	POWER_UNIT=`printf %f ${POWER_UNIT}`

	# 12:8
	ENERGY_UNIT=$(( ($val & `genmask32 12 8`) >> 8 ))
	ENERGY_UNIT=`bc -l <<< "1 / (2 ^ ${ENERGY_UNIT})"`
	ENERGY_UNIT=`printf %f ${ENERGY_UNIT}`

	# 19:16
	TIME_UNIT=$(( ($val & `genmask32 19 16`) >> 16 ))
	TIME_UNIT=`bc -l <<< "1 / (2 ^ ${TIME_UNIT})"`
	TIME_UNIT=`printf %f ${TIME_UNIT}`
}

unit_get()
{
	__unit_get

	echo "power unit: ${POWER_UNIT} W"
	echo "energy unint: ${ENERGY_UNIT} J"
	echo "time unit: ${TIME_UNIT} s"
  echo ""
}

pl_parse()
{
	local store_var=$1
	local val=$2
	local pl1=
	local pl1_calc=
	local pl1_en=
	local pl1_clamp=
	local pl1_time=
	local pl1_time_calc=
	local pl2=
	local pl2_calc=
	local pl2_en=
	local pl2_clamp=
	local pl2_time=
	local pl2_time_calc=
	local lock=
	local time_lo=
	local time_hi=

	if [ -z $store_var ]; then
		exit 1
	fi

	# 14:0
	pl1=$(( ($val & `genmask64 14 0`) >> 0 ))
	pl1_calc=`bc -l <<< "$pl1 * ${POWER_UNIT}"`
	pl1_calc=`printf %.0f $pl1_calc`
	pl1=`printf 0x%x $pl1`

	# 15:15
	pl1_en=$(( ($val & `genmask64 15 15`) >> 15 ))

	# 16:16
	pl1_clamp=$(( ($val & `genmask64 16 16`) >> 16 ))

	# 23:17
	pl1_time=$(( ($val & `genmask64 23 17`) >> 17 ))
	pl1_time=`printf 0x%x $pl1_time`
	# 21:17
	time_lo=`printf %d $(( $pl1_time & 0x1f ))`
	# 23:22
	time_hi=`printf %d $(( ($pl1_time & 0x60) >> 5 ))`
	pl1_time_calc=`bc -l <<< "(2 ^ $time_lo) * (1.0 + ($time_hi / 4.0)) * ${TIME_UNIT}"`
	pl1_time_calc=`printf %f $pl1_time_calc`

	# 46:32
	pl2=$(( ($val & `genmask64 46 32`) >> 32 ))
	pl2_calc=`bc -l <<< "$pl2 * ${POWER_UNIT}"`
	pl2_calc=`printf %.0f $pl2_calc`
	pl2=`printf 0x%x $pl2`

	# 47:47
	pl2_en=$(( ($val & `genmask64 47 47`) >> 47 ))

	# 48:48
	pl2_clamp=$(( ($val & `genmask64 48 48`) >> 48 ))

	# 55:49
	pl2_time=$(( ($val & `genmask64 55 49`) >> 49 ))
	pl2_time=`printf 0x%x $pl2_time`
	# 53:49
	time_lo=`printf %d $(( ${pl2_time} & 0x1f ))`
	# 53:52
	time_hi=`printf %d $(( (${pl2_time} & 0x60) >> 5 ))`
	pl2_time_calc=`bc -l <<< "2 ^ $time_lo * (1.0 + ($time_hi / 4.0)) * ${TIME_UNIT}"`
	pl2_time_calc=`printf %f $pl2_time_calc`

	# 63:63
	lock=$(( (($val & `genmask64 63 63`) >> 63) & 1 ))

	if [ x"$store_var" == x"msr" ]; then
		MSR_PL1=$pl1
		MSR_PL1_CALC=$pl1_calc
		MSR_PL1_EN=$pl1_en
		MSR_PL1_CLAMP=$pl1_clamp
		MSR_PL1_TIMEWD=$pl1_time
		MSR_PL1_TIMEWD_CALC=$pl1_time_calc
		MSR_PL2=$pl2
		MSR_PL2_CALC=$pl2_calc
		MSR_PL2_EN=$pl2_en
		MSR_PL2_CLAMP=$pl2_clamp
		MSR_PL2_TIMEWD=$pl2_time
		MSR_PL2_TIMEWD_CALC=$pl2_time_calc
		MSR_PL_LOCK=$lock
	elif [ x"$store_var" == x"mmio" ]; then
		MMIO_PL1=$pl1
		MMIO_PL1_CALC=$pl1_calc
		MMIO_PL1_EN=$pl1_en
		MMIO_PL1_CLAMP=$pl1_clamp
		MMIO_PL1_TIMEWD=$pl1_time
		MMIO_PL1_TIMEWD_CALC=$pl1_time_calc
		MMIO_PL2=$pl2
		MMIO_PL2_CALC=$pl2_calc
		MMIO_PL2_EN=$pl2_en
		MMIO_PL2_CLAMP=$pl2_clamp
		MMIO_PL2_TIMEWD=$pl2_time
		MMIO_PL2_TIMEWD_CALC=$pl2_time_calc
		MMIO_PL_LOCK=$lock
	fi
}

__msr_pl_get()
{
	local ret=`msr_read 0 0 0x610`

	if [ $? -ne 0 ]; then
		exit 1
	fi

	ret=`echo $ret | tr -d '\r'`
	local hi=`echo $ret | awk '{print $4}'`
	local lo=`echo $ret | awk '{print $5}'`
	local val=`printf 0x%016x $(( ($hi << 32) | $lo ))`

	pl_parse msr $val
}

msr_pl_get()
{
	__msr_pl_get

	echo "MSR:"
	echo ""
	echo "PL1:"
	echo "${MSR_PL1} (${MSR_PL1_CALC} W)"
	echo "en: ${MSR_PL1_EN} clamp: ${MSR_PL1_CLAMP}"
	echo "time window: ${MSR_PL1_TIMEWD} (${MSR_PL1_TIMEWD_CALC} s)"
	echo ""
	echo "PL2: "
	echo "${MSR_PL2} (${MSR_PL2_CALC} W)"
	echo "en: ${MSR_PL2_EN} clamp: ${MSR_PL2_CLAMP}"
	echo "time window: ${MSR_PL2_TIMEWD} (${MSR_PL2_TIMEWD_CALC} s)"
	echo ""
	echo "locked: ${MSR_PL_LOCK}"
	echo ""
}

__mmio_pl_get()
{
	# MCHBAR base address for 12900H = 0xfedc0000 
	local val=`mmio_read 64 0xfedc59a0`

	if [ $? -ne 0 ]; then
		exit 1
	fi

	pl_parse mmio $val
}

mmio_pl_get()
{
	__mmio_pl_get

	echo "MMIO:"
	echo ""
	echo "PL1:"
	echo "${MMIO_PL1} (${MMIO_PL1_CALC} W)"
	echo "en: ${MMIO_PL1_EN} clamp: ${MMIO_PL1_CLAMP}"
	echo "time window: ${MMIO_PL1_TIMEWD} (${MMIO_PL1_TIMEWD_CALC} s)"
	echo ""
	echo "PL2: "
	echo "${MMIO_PL2} (${MMIO_PL2_CALC} W)"
	echo "en: ${MMIO_PL2_EN} clamp: ${MMIO_PL2_CLAMP}"
	echo "time window: ${MMIO_PL2_TIMEWD} (${MMIO_PL2_TIMEWD_CALC} s)"
	echo ""
	echo "locked: ${MMIO_PL_LOCK}"
	echo ""
}

pl_get()
{
	unit_get
	
	if [ -z $1 ]; then
		mmio_pl_get
		msr_pl_get
	else
		${1}_pl_get
	fi
}

pl_limit_set()
{
	local watt=$1
	local en=$2
	local clamp=$3

	set -x

	local pl=`bc -l <<< "$watt / ${POWER_UNIT}"`
	pl=`printf %.0f $pl`

	en=$(( $en << 15 ))
	clamp=$(( $clamp << 16 ))

	echo $pl

	echo $(( $pl | $en | $clamp ))
}

msr_limit_set()
{
	local pl=$1
	local watt=$2
	local en=$3
	local clamp=$4
	local val=`pl_limit_set $watt $en $clamp`
}

pl_set()
{
	local io=$1
	local set=$2
	local pl=$3
	local watt=$4
	local en=$5
	local clamp=$6
	local time=$4

	if [ x"$io" = "" -o x"$set" = x"" ]; then
		echo "invalid args"
		exit 1
	fi

	__unit_get

	__${io}_pl_get

	case $2 in
	limit )
		if [ x"$pl" = x"" -o x"$watt" = x"" -o x"$en" = x"" -o x"$clamp" = x"" ]; then
			echo "invalid args for command"
			exit 1
		fi

		${io}_limit_set $pl $watt $en $clamp
	;;
	esac
}

if [ $# -lt 1 ]; then
	echo "pl_get [msr/mmio]"
	# echo "pl_set <msr/mmio> limit <pl1/pl2> <watt> <en> <clamp>"
	# echo "pl_set <msr/mmio> time <pl1/pl2> <secs>"
	# echo "pl_set <msr/mmio> lock"
fi

if [ x"$1" = x"wait" ]; then 
	WAIT_USER=1
	shift
fi

cmd=$1
shift

if type "$cmd" >/dev/null 2>/dev/null; then
    $cmd $@
fi

ntdrvldr_remove

if [ x"${WAIT_USER}" = x"1" ]; then
	echo "Press Enter to continue..."
	read
fi