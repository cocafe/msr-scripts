#!/bin/bash

export PATH=/cygdrive/d/Program/cygwin64/bin:$PATH

CWD="$(dirname "$0")"

source "${CWD}/reg.sh"
source "${CWD}/../bitops.sh"
source "${CWD}/../msr.sh"
source "${CWD}/../physram.sh"

# 610H MSR_PKG_POWER_LIMIT (RW)
#
#     14:0 = Pkg power limit = Powerunit * decimal
#     15:15 = Pkg power enabled (bool)
#     16:16 = Pkg clamping limit (bool)
#     23:17 = Pkg power limit time window = 2^(21:17 bit) * (1.0 + (23:22 bit)/4.0 ) * Timeunit
#
#     46:32 = Pkg power limit 2 = Powerunit * decimal
#     47:47 = Pkg power 2 enabled (bool)
#     48:48 = Pkg clamping limit 2 (bool)
#     55:49 = Pkg power limit time window = 2^(53:49 bit) * (1.0 + (55:54 bit)/4.0 ) * Timeunit
#
#     63:63 = MSR lock (bool)

# 606H MSR_RAPL_POWER_UNIT (RO)
#     3:0 = Power unit (W) = 1/2^(decimal)W - def: 0.125W
#     12:8 = Energy unit (J) = 1/2^(decimal)J - def: 0.00006103515625J
#     19:16 = Time unit (sec) = 1/2^(decimal)sec - def: 0.0009765625sec

POWER_UNIT=
ENERGY_UNIT=
TDP_LOCK=0
TIME_UNIT=
TIME_MAX=0
TIME_MAX_VAL=$(genmask64 6 0)
PL1_SEC=
PL2_SEC=

unit_get()
{
  local ret=`msr_read 0 0 0x606`
  local val=

  if [ $? -ne 0 ]; then
    exit 1
  fi

  val=`echo $ret | awk '{print $5}'`

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

#
# default:
# PL1 EN = 1
# PL1 CLAMP = 1
# PL1 = 0x6f 56s
# PL2 EN = 1
# PL2 CLAMP = 0
# PL2 = 0x21 0.002442s
#

time_calc()
{
  local secs=$1
  local mul=0
  local ret=

  `python3 -c "float($secs)"` 2>&1 1>/dev/null
  if [ $? -ne 0 ]; then
    echo "0x00"
    return
  fi

  if [ x`python3 -c "print($secs == 0)"` = x"True" ]; then
    echo "0x00"
    return
  fi

  while :; do
    local t=`python3 -c "import math
print(int(math.log2(${secs} / (0.000977 * (1 + $mul / 4)))))"`

    if [ x"$ret" = x"" ]; then
      ret=$t
    else
      local d1=`python3 -c "print(abs($secs - $ret))"`
      local d2=`python3 -c "print(abs($t - $ret))"`

      if [ x`python3 -c "print($d2 < $d1)"` = x"True" ]; then
        ret=$t
      fi
    fi

    if [ $mul -ge 3 ]; then
      break;
    fi

    mul=$(($mul + 1))
  done

  echo `python3 -c "print(hex($ret | $mul << 5))"`
}

pl_val()
{
  local pl1=$(printf %.0f `bc -l <<< "$1 / ${POWER_UNIT}"`)
  local pl2=$(printf %.0f `bc -l <<< "$2 / ${POWER_UNIT}"`)
  local pl1_en=1
  local pl1_clamp=1
  local pl1_time=0x6f
  local pl2_en=1
  local pl2_clamp=0
  local pl2_time=0x21
  local lock=${TDP_LOCK}

  if [ x"${PL1_SEC}" != x"" -a x"${PL1_SEC}" != x"-1" ]; then 
    pl1_time=`time_calc ${PL1_SEC}`
  fi

  if [ x"${PL2_SEC}" != x"" -a x"${PL2_SEC}" != x"-1" ]; then
    pl2_time=`time_calc ${PL2_SEC}`
  fi

  if [ ${TIME_MAX} -ne 0 ]; then
    pl1_time=${TIME_MAX_VAL}
    pl2_time=${TIME_MAX_VAL}
  fi

  local val=$(( ($lock << 63)      | \
                ($pl2_time << 49)  | \
                ($pl2_clamp << 48) | \
                ($pl2_en << 47)    | \
                ($pl2 << 32)       | \
                ($pl1_time << 17)  | \
                ($pl1_clamp << 16) | \
                ($pl1_en << 15)    | \
                ($pl1) ))

  printf "0x%016x" $val
}

pl_set()
{
  local val=`pl_val $1 $2`

  local edx=`printf 0x%08x $(( ($val >> 32) & $u32max ))`
  local eax=`printf 0x%08x $(( $val & $u32max ))`

  if [ x"$TDP_LOCK" = x"1" ]; then
    echo "notice: register will be locked"
  fi

  echo "$edx $eax $val"

  msr_write 0 0 ${MSR_PKG_PWR} $edx $eax
  mmio_write ${MMIO_PKG_PWR_WIDTH} ${MMIO_PKG_PWR} $val
}

usage()
{
  echo "usage:"
  echo "  $0 [-l] [-t] [-m] <pl1> <pl2>"
  echo "  -l lock"
  echo "  -t set max time duration"
  echo "  -m manual input values"
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

while getopts "lmt" o; do
  case "${o}" in
    l)
      TDP_LOCK=1
      ;;
    t)
      TIME_MAX=1
      ;;
    m)
      MANUAL=1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

# 35 55
# 55 95
# 65 115
PL1=$1
PL2=$2

if [ x"${MANUAL}" = x"1" ]; then
  echo "Typical PL1/PL2: <35/55> <55/95> <65/115>"
  echo "<pl1> <pl2> <pl1_ms/-1> <pl2_ms/-1> <lock> <is_max_time>"
  read PL1 PL2 PL1_SEC PL2_SEC TDP_LOCK TIME_MAX 
fi

echo "pl1: $PL1 pl2: $PL2 pl1_time: ${PL1_SEC}sec pl2_time: ${PL2_SEC}sec lock: $TDP_LOCK time max: $TIME_MAX"

unit_get
pl_set $PL1 $PL2
ntdrvldr_remove

if [ x"${MANUAL}" = x"1" ]; then
  echo "done"
  read
fi