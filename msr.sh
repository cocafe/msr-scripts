#!/bin/bash

MSR_CMD=/cygdrive/d/Program/msr-watchdog/msr-cmd.exe

NR_CPU=`cat /proc/cpuinfo | grep processor | wc -l`
NR_CPUGRP=$((${NR_CPU} / 64))

if [ ${NR_CPUGRP} -eq 0 ]; then
  NR_CPUGRP=1
fi

IS_PROC_GROUPED=0
if [ ${NR_CPU} -gt 64 ]; then
  IS_PROC_GROUPED=1
fi

err_echo()
{
  >&2 echo $@
}

# deprecated
____msr_write()
{
  local pkg=$1; shift
  local cpu=$1; shift
  local reg=$1; shift
  local edx=$1; shift
  local eax=$1; shift

  if [ $# -ne 5 ]; then
    err_echo "invalid parameters: $@"
    err_echo "press any key to exit..."
    read
    exit -1
  fi

  if [ x"$pkg" != x"A" -a x"$pkg" != x"a" ]; then
    if [ $pkg -ge 1 -a ${IS_PROC_GROUPED} == 0 ]; then
      return 0
    fi
  fi

  err_echo "msr write: $@"

  if [ "$cpu" = "A" -o "$cpu" = "ALL" ]; then
      if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
        ${MSR_CMD} -A -s -d write $reg $edx $eax
      else
        ${MSR_CMD} -g $pkg -a -s -d write $reg $edx $eax
      fi
  else
    if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
      local i=0
      while [ $i -lt ${NR_CPUGRP} ]; do
        ${MSR_CMD} -g $i -p $cpu -s -d write $reg $edx $eax
        i=$(($i + 1))
      done
    else
      ${MSR_CMD} -g $pkg -p $cpu -s -d write $reg $edx $eax
    fi
  fi

  local ret=$?

  if [ $ret -ne 0 ]; then
    err_echo "write msr failed: $@"
    err_echo "press any key to continue..."
    read
  fi

  return $ret
}

msr_write()
{
  if [ $# -ne 5 ]; then
    err_echo "invalid parameters: $@"
    err_echo "press any key to exit..."
    read
    exit -1
  fi

  local pkg=$1; shift
  local cpu=$1; shift
  local reg=$1; shift
  local edx=$1; shift
  local eax=$1; shift

  local opt="-s -d"

  if [ x"$pkg" == x"A" -o x"$pkg" == x"a" ]; then
    opt="$opt -g A"
  else
    opt="$opt -g $pkg"
  fi

  if [ x"$cpu" == x"A" -o x"$cpu" == x"a" ]; then
    opt="$opt -a"
  else
    opt="$opt -p $cpu"
  fi

  ( set -x; ${MSR_CMD} $opt write $reg $edx $eax )

  local ret=$?

  if [ $ret -ne 0 ]; then
    err_echo "write msr failed: $@"
    err_echo "press any key to continue..."
    read
  fi

  return $ret
}

msr_read()
{
  local pkg=$1
  local cpu=$2
  local reg=$3

  if [ $# -ne 3 ]; then
    err_echo "invalid parameters: $@"
    err_echo "press any key to exit..."
    read
    exit -1
  fi

  if [ x"$pkg" != x"A" -a x"$pkg" != x"a" ]; then
    if [ $pkg -ge 1 -a ${IS_PROC_GROUPED} == 0 ]; then
      return 0
    fi
  fi

  if [ "$cpu" == "A" -o "$cpu" == "ALL" -o x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
    err_echo "msr_read() can only read one cpu..."
    read
    exit -1
  fi

  local regval=`${MSR_CMD} -d -g $pkg -p $cpu read $reg`
  if [ "$regval" == "" ]; then
    err_echo "failed to read msr $reg"
    read
    return -1
  fi

  echo $regval | tr -d '\r'

  return 0
}

# deprecated
____msr_setbit()
{
  local pkg=$1
  local cpu=$2
  local reg=$3
  local bit=$4
  local val=$5

  local regval=0

  if [ $# -ne 5 ]; then
    err_echo "invalid parameters: $@"
    err_echo "press any key to exit..."
    read
    exit -1
  fi

  if [ x"$pkg" != x"A" -a x"$pkg" != x"a" ]; then
    if [ $pkg -ge 1 -a ${IS_PROC_GROUPED} == 0 ]; then
      return 0
    fi
  fi

  if [ $bit -gt 63 -o $bit -lt 0 ]; then
    err_echo "invalid bit shift: $bit"
    read
    exit -1
  fi

  if [ "$val" != "0" -a "$val" != "1" ]; then
    err_echo "invalid bit value: $val"
    read
  fi

  err_echo "msr setbit: $@"

  #
  # FIXME: !!! LAZY IMPL !!!
  #
  if [ "$cpu" = "A" -o "$cpu" = "ALL" ]; then
    if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
      regval=`${MSR_CMD} -d -g 0 -p 0 read $reg`
    else
      regval=`${MSR_CMD} -d -g $pkg -p 0 read $reg`
    fi
  else
    if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
      regval=`${MSR_CMD} -d -g 0 -p $cpu read $reg`
    else
      regval=`${MSR_CMD} -d -g $pkg -p $cpu read $reg`
    fi
  fi
  if [ "$regval" == "" ]; then
    err_echo "failed to read $reg"
    return -1
  fi

  local edx=`echo $regval | awk '{print $3}'`
  local eax=`echo $regval | awk '{print $4}'`
  edx=`printf "0x%x" $edx`
  eax=`echo $eax | tr -d '\r'`
  eax=`printf "0x%x" $eax`

  if [ $bit -gt 31 ]; then
    bit=$(($bit - 32))
    edx=`printf "0x%x" $((    ($edx & ~(1 << $bit)) | ($val << $bit)    ))`
  else
    eax=`printf "0x%x" $((    ($eax & ~(1 << $bit)) | ($val << $bit)    ))`
  fi

  if [ "$cpu" = "A" -o "$cpu" = "ALL" ]; then
      if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
        ${MSR_CMD} -A -s -d write $reg $edx $eax
      else
        ${MSR_CMD} -g $pkg -a -s -d write $reg $edx $eax
      fi
  else
    if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
      local i=0
      while [ $i -lt ${NR_CPUGRP} ]; do
        ${MSR_CMD} -g $i -p $cpu -s -d write $reg $edx $eax
        i=$(($i + 1))
      done
    else
      ${MSR_CMD} -g $pkg -p $cpu -s -d write $reg $edx $eax
    fi
  fi

  local ret=$?

  if [ $ret -ne 0 ]; then
    err_echo "write msr failed: package: $pkg cpu: $cpu reg: $reg edx: $edx eax: $eax"
    err_echo "press any key to continue..."
    read
  fi

  return $ret
}

msr_setbit()
{
  if [ $# -ne 5 ]; then
    err_echo "invalid parameters: $@"
    err_echo "press any key to exit..."
    read
    exit -1
  fi

  local pkg=$1; shift
  local cpu=$1; shift
  local reg=$1; shift
  local bit=$1; shift
  local val=$1; shift

  local opt="-s -d"

  if [ $bit -gt 63 -o $bit -lt 0 ]; then
    err_echo "invalid bit shift: $bit"
    read
    exit -1
  fi

  if [ "$val" != "0" -a "$val" != "1" ]; then
    err_echo "invalid bit value: $val"
    read
  fi

  if [ x"$pkg" == x"A" -o x"$pkg" == x"a" ]; then
    opt="$opt -g A"
  else
    opt="$opt -g $pkg"
  fi

  if [ x"$cpu" == x"A" -o x"$cpu" == x"a" ]; then
    opt="$opt -a"
  else
    opt="$opt -p $cpu"
  fi

  ( set -x; ${MSR_CMD} $opt setbit $reg $bit $val )

  local ret=$?

  if [ $ret -ne 0 ]; then
    err_echo "write msr failed: $@"
    err_echo "press any key to continue..."
    read
  fi

  return $ret
}

# deprecated
____msr_rmw()
{
  local pkg=$1
  local cpu=$2
  local reg=$3
  local hi=$4
  local lo=$5
  local val=$6

  local regval=0

  if [ $# -ne 6 ]; then
    err_echo "invalid parameters: $@"
    err_echo "press any key to exit..."
    read
    exit -1
  fi

  if [ $pkg -ge 1 -a ${IS_PROC_GROUPED} == 0 ]; then
    # err_echo "pkg $pkg is not available"
    return 0
  fi

  if [ "$cpu" = "A" -o "$cpu" = "ALL" ]; then
    if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
      regval=`${MSR_CMD} -d -g 0 -p 0 read $reg`
    else
      regval=`${MSR_CMD} -d -g $pkg -p 0 read $reg`
    fi
  else
    if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
      regval=`${MSR_CMD} -d -g 0 -p $cpu read $reg`
    else
      regval=`${MSR_CMD} -d -g $pkg -p $cpu read $reg`
    fi
  fi

  if [ "$regval" == "" ]; then
    err_echo "failed to read $reg"
    return -1
  fi

  local edx=`echo $regval | awk '{print $3}'`
  local eax=`echo $regval | awk '{print $4}'`
  edx=`printf "0x%x" $edx`
  eax=`echo $eax | tr -d '\r'`
  eax=`printf "0x%x" $eax`
  regval=`printf "0x%08x%08x" $edx $eax`

  local mask=`genmask64 $hi $lo`
  local imask=$(( $u64max ^ $mask ))

  val=$(( $val << $lo ))
  regval=$(( $regval & $imask ))
  regval=`printf "0x%016x" $(( $regval | $val ))`
  edx=`printf "0x%08x" $(( ($regval >> 32) & $u32max ))`
  eax=`printf "0x%08x" $(( $regval & $u32max ))`

  err_echo "msr rmw: $pkg $cpu $reg $mask $regval $edx $eax"

  if [ "$cpu" = "A" -o "$cpu" = "ALL" ]; then
      if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
        ${MSR_CMD} -A -s -d write $reg $edx $eax
      else
        ${MSR_CMD} -g $pkg -a -s -d write $reg $edx $eax
      fi
  else
    if [ x"$pkg" = x"A" -o x"$pkg" = x"a" ]; then
      local i=0
      while [ $i -lt ${NR_CPUGRP} ]; do
        ${MSR_CMD} -g $i -p $cpu -s -d write $reg $edx $eax
        i=$(($i + 1))
      done
    else
      ${MSR_CMD} -g $pkg -p $cpu -s -d write $reg $edx $eax
    fi
  fi

  local ret=$?

  if [ $ret -ne 0 ]; then
    err_echo "write msr failed: package: $pkg cpu: $cpu reg: $reg edx: $edx eax: $eax"
    err_echo "press any key to continue..."
    read
  fi

  return $ret
}


msr_rmw()
{
    if [ $# -ne 6 ]; then
    err_echo "invalid parameters: $@"
    err_echo "press any key to exit..."
    read
    exit -1
  fi

  local pkg=$1; shift
  local cpu=$1; shift
  local reg=$1; shift
  local hi=$1; shift
  local lo=$1; shift
  local val=$1; shift

  local opt="-s -d"

  if [ $hi -gt 63 -o $hi -lt 0 ]; then
    err_echo "invalid high bit: $bit"
    read
    exit -1
  fi

  if [ $lo -gt 63 -o $lo -lt 0 ]; then
    err_echo "invalid low bit: $bit"
    read
    exit -1
  fi

  if [ $lo -gt $hi ]; then
    err_echo "low bit is higher than high bit"
    read
    exit -1
  fi

  if [ x"$pkg" == x"A" -o x"$pkg" == x"a" ]; then
    opt="$opt -g A"
  else
    opt="$opt -g $pkg"
  fi

  if [ x"$cpu" == x"A" -o x"$cpu" == x"a" ]; then
    opt="$opt -a"
  else
    opt="$opt -p $cpu"
  fi

  ( set -x; ${MSR_CMD} $opt rmw $reg $hi $lo $val )

  local ret=$?

  if [ $ret -ne 0 ]; then
    err_echo "write msr failed: $@"
    err_echo "press any key to continue..."
    read
  fi

  return $ret
}