# MSR-Scripts

⚠ Shell scripts is dangerous, verify by yourself before using them. 

⚠ These scripts are intended for badass power user, if you don't understand them fully, don't use them

⚠ These scripts are written by n00b, they may contain bugs 🐞🐞🐞!!

⚠ Use on your own risk, you have been warned

---

#### Require

- `cygwin64` for bash interpreter 
- `Nsudo` for calling from shortcut with highest privilege 
- `msr-cmd` [latest version](https://github.com/cocafe/msr-utility)
- `physmem` [latest version](https://github.com/cocafe/physmem)

#### Note

Change the PATH statement `export PATH=$PATH:/cygdrive/d/Program/cygwin64/bin` to your cygwin environment in scripts before using it.

Recommended that write your own version if possible.

#### Some Examples

[v3_turbo.sh](2699v3/v3_turbo.sh) 

Patch and tweak your XEON V3 in Windows™ instead of in a hardcoded UEFI module.

You can get both latest microcode fix (can increase performance) and FULL turbo.

[tdp_set.sh](12900H/tdp_set.sh) 

TDP scripts for 12Gen mobile, may work for similar Intel arch. Have feature like MMIO SYNC in throttlestop.

