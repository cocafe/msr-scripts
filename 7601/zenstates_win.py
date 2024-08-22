#!/usr/bin/python
import struct
import os
import glob
import argparse
import re

r = re.compile('[ \t\n\r:]+')

dry_run = False

pstates = range(0xC0010064, 0xC001006C)

nr_cpu = 0
nr_cpugrp = 0

def nr_cpu_get():
    try:
        ret = r.split(os.popen("cat /proc/cpuinfo | grep processor | wc -l").read())
        return int(ret[0], 10)
    except:
        raise OSError("failed to get count of CPU")

def nr_cpugrp_get():
    ret = int(nr_cpu / 64)
    if ret == 0:
        return 1
    else:
        return ret

def is_grouped():
    if nr_cpu > 64:
        return 1
    else:
        return 0

def writemsr(msr, val, cpu = -1):
    eax = val & ((1 << 32) - 1)
    edx = (val & ~((1 << 32) - 1)) >> 32
    # print("writemsr: " + str(hex(msr)) + " " + str(hex(edx)) + " " + str(hex(eax)) + " " + str(cpu))
    if dry_run == True:
        return
    try:
        if cpu == -1:
            os.popen("msr-cmd -d -s -A write " + str(hex(msr)) + " " + str(hex(edx)) + " " + str(hex(eax)))
            return
        else:
            os.popen("msr-cmd -s -p " + str(cpu) + " write " + str(hex(msr)) + " " + str(hex(edx)) + " " + str(hex(eax)))
            return
    except:
        raise OSError("failed to write msr")

def readmsr(msr, cpu = 0, grp = 0):
    try:
        ret = r.split(os.popen("msr-cmd -d -g " + str(grp) + " -p " + str(cpu) + " read " + str(hex(msr))).read())
        val = (int(ret[3], 16) << 32) | int(ret[4], 16)
        return val
    except:
        raise OSError("failed to read msr")

def pstate2str(val):
    if val & (1 << 63):
        fid = val & 0xff
        did = (val & 0x3f00) >> 8
        vid = (val & 0x3fc000) >> 14
        ratio = 25*fid/(12.5 * did)
        vcore = 1.55 - 0.00625 * vid
        return "Enabled - FID = %X - DID = %X - VID = %X - Ratio = %.2f - vCore = %.5f" % (fid, did, vid, ratio, vcore)
    else:
        return "Disabled"

def setbits(val, base, length, new):
    return (val ^ (val & ((2 ** length - 1) << base))) + (new << base)

def setfid(val, new):
    return setbits(val, 0, 8, new)

def setdid(val, new):
    return setbits(val, 8, 6, new)

def setvid(val, new):
    return setbits(val, 14, 8, new)

def _hex(x):
    return int(x, 16)

parser = argparse.ArgumentParser(description='Sets P-States for Ryzen processors')
parser.add_argument('-l', '--list', action='store_true', help='List all P-States')
parser.add_argument('-p', '--pstate', default=-1, type=int, choices=range(8), help='P-State to set')
parser.add_argument('--enable', action='store_true', help='Enable P-State')
parser.add_argument('--disable', action='store_true', help='Disable P-State')
parser.add_argument('-f', '--fid', default=-1, type=_hex, help='FID to set (in hex)')
parser.add_argument('-d', '--did', default=-1, type=_hex, help='DID to set (in hex)')
parser.add_argument('-v', '--vid', default=-1, type=_hex, help='VID to set (in hex)')
parser.add_argument('--ratio', type=float, help='frequency multipiler')
parser.add_argument('--vcore', type=float, help='Vcore in V')
parser.add_argument('--c6-enable', action='store_true', help='Enable C-State C6')
parser.add_argument('--c6-disable', action='store_true', help='Disable C-State C6')
parser.add_argument('--dry-run', action='store_true', help='Do not apply to HW')

args = parser.parse_args()

nr_cpu = nr_cpu_get()
nr_cpugrp = nr_cpugrp_get()

if args.ratio:
    if args.did <= 0:
        print('Div ID need to be specified')
        exit()
    args.fid = int(((12.5 * args.did) * args.ratio) / 25)
    # print('fid = ' + str(hex(args.fid)))

if args.vcore:
    args.vid = int((1.55 - args.vcore) / 0.00625)
    # print('vid = ' + str(hex(args.vid)))

if args.list:
    for g in range(0, nr_cpugrp):
        print("Process Group " + str(g) + ":")
        for p in range(len(pstates)):
            print('P' + str(p) + " - " + pstate2str(readmsr(pstates[p], 0, g)))
        print('C6 State - Package - ' + ('Enabled' if readmsr(0xC0010292, 0, g) & (1 << 32) else 'Disabled'))
        print('C6 State - Core - ' + ('Enabled' if readmsr(0xC0010296, 0, g) & ((1 << 22) | (1 << 14) | (1 << 6)) == ((1 << 22) | (1 << 14) | (1 << 6)) else 'Disabled'))

if args.pstate >= 0:
    new = old = readmsr(pstates[args.pstate])
    print('Current P' + str(args.pstate) + ': ' + pstate2str(old))
    if args.enable:
        new = setbits(new, 63, 1, 1)
        print('Enabling state')
    if args.disable:
        new = setbits(new, 63, 1, 0)
        print('Disabling state')
    if args.fid >= 0:
        new = setfid(new, args.fid)
        print('Setting FID to %X' % args.fid)
    if args.did >= 0:
        new = setdid(new, args.did)
        print('Setting DID to %X' % args.did)
    if args.vid >= 0:
        new = setvid(new, args.vid)
        print('Setting VID to %X' % args.vid)
    if new != old:
        if not (readmsr(0xC0010015) & (1 << 21)):
            print('Locking TSC frequency')
            val = readmsr(0xC0010015, 0) | (1 << 21)
            writemsr(0xC0010015, val)
        print('New P' + str(args.pstate) + ': ' + pstate2str(new))
        writemsr(pstates[args.pstate], new)

if args.c6_enable:
    writemsr(0xC0010292, readmsr(0xC0010292) | (1 << 32))
    writemsr(0xC0010296, readmsr(0xC0010296) | ((1 << 22) | (1 << 14) | (1 << 6)))
    print('Enabling C6 state')

if args.c6_disable:
    writemsr(0xC0010292, readmsr(0xC0010292) & ~(1 << 32))
    writemsr(0xC0010296, readmsr(0xC0010296) & ~((1 << 22) | (1 << 14) | (1 << 6)))
    print('Disabling C6 state')

if not args.list and args.pstate == -1 and not args.c6_enable and not args.c6_disable:
    parser.print_help()
