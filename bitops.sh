#!/bin/bash

u32max=0xffffffff
u64max=0xffffffffffffffff

genmask32()
{
  local hi=$1
  local lo=$2
  local hm=$(( $u32max >> (31 - $hi) ))
  local lm=$(( ($u32max << $lo) & $u32max ))

  printf "0x%08x" $(($hm & $lm))
}

genmask64()
{
  local hi=$1
  local lo=$2
  local hm=$(( ($u64max ^ ($u64max << $hi )) | (1 << $hi) ))
  local lm=$(( $u64max << $lo ))

  printf "0x%016x" $(($hm & $lm))
}

tohex()
{
  printf "%x" $1
}