#!/bin/bash

physram=/cygdrive/d/Program/physram/physram.exe
# physram=/cygdrive/d/Repo/physram/cmake-build-debug/physram.exe
ntdrvldr=/cygdrive/d/Program/physram/ntdrvldr.exe

mmio_write()
{
  local width=$1
  local addr=$2
  local val=$3

  if [ x"$1" = x"" -o x"$2" = x"" -o x"$3" = x"" ]; then
    echo "invalid args"
    exit 1
  fi

  >&2 echo "mmio_write ${width} ${addr} ${val}"

  $physram -s write${width} $addr $val

  if [ $? -ne 0 ]; then
    echo "failed to write address ${addr}"
    read
    exit 1
  fi
}

mmio_read()
{
  local width=$1
  local addr=$2
  local val=`$physram read${width} $addr`

  if [ x"$1" = x"" -o x"$2" = x"" ]; then
    echo "invalid args"
    exit 1
  fi

  if [ $? -ne 0 ]; then
    echo "failed to read address ${addr}"
    read
    exit 1
  fi

  echo $val | tr -d '\r' | awk '{printf $2}'
}

mmio_drv_install()
{
  $physram driver install
}

mmio_drv_remove()
{
  $physram driver remove
}

ntdrvldr_remove()
{
  $ntdrvldr -u -n asmmap64 1
}
