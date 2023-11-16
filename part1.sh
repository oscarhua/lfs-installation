#!/bin/bash
set -e

apt update
apt upgrade -y
apt install -y bison gcc g++ m4 make texinfo fdisk
ln -sf bash /bin/sh


# Chapter 2.2 ("Chapter" will be omitted after this)
cat > version-check.sh << "EOF"
#!/bin/bash
# A script to list version numbers of critical development tools

# If you have tools installed in other directories, adjust PATH here AND
# in ~lfs/.bashrc (section 4.4) as well.

LC_ALL=C 
PATH=/usr/bin:/bin

bail() { echo "FATAL: $1"; exit 1; }
grep --version > /dev/null 2> /dev/null || bail "grep does not work"
sed '' /dev/null || bail "sed does not work"
sort   /dev/null || bail "sort does not work"

ver_check()
{
   if ! type -p $2 &>/dev/null
   then 
     echo "ERROR: Cannot find $2 ($1)"; return 1; 
   fi
   v=$($2 --version 2>&1 | grep -E -o '[0-9]+\.[0-9\.]+[a-z]*' | head -n1)
   if printf '%s\n' $3 $v | sort --version-sort --check &>/dev/null
   then 
     printf "OK:    %-9s %-6s >= $3\n" "$1" "$v"; return 0;
   else 
     printf "ERROR: %-9s is TOO OLD ($3 or later required)\n" "$1"; 
     return 1; 
   fi
}

ver_kernel()
{
   kver=$(uname -r | grep -E -o '^[0-9\.]+')
   if printf '%s\n' $1 $kver | sort --version-sort --check &>/dev/null
   then 
     printf "OK:    Linux Kernel $kver >= $1\n"; return 0;
   else 
     printf "ERROR: Linux Kernel ($kver) is TOO OLD ($1 or later required)\n" "$kver"; 
     return 1; 
   fi
}

# Coreutils first because-sort needs Coreutils >= 7.0
ver_check Coreutils      sort     7.0 || bail "--version-sort unsupported"
ver_check Bash           bash     3.2
ver_check Binutils       ld       2.13.1
ver_check Bison          bison    2.7
ver_check Diffutils      diff     2.8.1
ver_check Findutils      find     4.2.31
ver_check Gawk           gawk     4.0.1
ver_check GCC            gcc      5.1
ver_check "GCC (C++)"    g++      5.1
ver_check Grep           grep     2.5.1a
ver_check Gzip           gzip     1.3.12
ver_check M4             m4       1.4.10
ver_check Make           make     4.0
ver_check Patch          patch    2.5.4
ver_check Perl           perl     5.8.8
ver_check Python         python3  3.4
ver_check Sed            sed      4.1.5
ver_check Tar            tar      1.22
ver_check Texinfo        texi2any 5.0
ver_check Xz             xz       5.0.0
ver_kernel 4.14

if mount | grep -q 'devpts on /dev/pts' && [ -e /dev/ptmx ]
then echo "OK:    Linux Kernel supports UNIX 98 PTY";
else echo "ERROR: Linux Kernel does NOT support UNIX 98 PTY"; fi

alias_check() {
   if $1 --version 2>&1 | grep -qi $2
   then printf "OK:    %-4s is $2\n" "$1";
   else printf "ERROR: %-4s is NOT $2\n" "$1"; fi
}
echo "Aliases:"
alias_check awk GNU
alias_check yacc Bison
alias_check sh Bash

echo "Compiler check:"
if printf "int main(){}" | g++ -x c++ -
then echo "OK:    g++ works";
else echo "ERROR: g++ does NOT work"; fi
rm -f a.out
EOF

bash version-check.sh


# 2.4, replace <x>
fdisk /dev/sd<x>
# Welcome to fdisk (util-linux 2.37.2).
# Changes will remain in memory only, until you decide to write them.
# Be careful before using the write command.


# Command (m for help): g
# Created a new GPT disklabel (GUID: 2003DD22-5B5C-C54F-B345-7431D3C71251).

# Command (m for help): n
# Partition number (1-128, default 1): 
# First sector (2048-1953525134, default 2048): 
# Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-1953525134, default 1953525134): +200M

# Created a new partition 1 of type 'Linux filesystem' and of size 200 MiB.

# Command (m for help): n
# Partition number (2-128, default 2): 
# First sector (411648-1953525134, default 411648): 
# Last sector, +/-sectors or +/-size{K,M,G,T,P} (411648-1953525134, default 1953525134): +200M

# Created a new partition 2 of type 'Linux filesystem' and of size 200 MiB.

# Command (m for help): n
# Partition number (3-128, default 3): 
# First sector (821248-1953525134, default 821248): 
# Last sector, +/-sectors or +/-size{K,M,G,T,P} (821248-1953525134, default 1953525134): +50G

# Created a new partition 3 of type 'Linux filesystem' and of size 50 GiB.

# Command (m for help): t
# Partition number (1-3, default 3): 1
# Partition type or alias (type L to list all): uefi

# Changed type of partition 'Linux filesystem' to 'EFI System'.

# Command (m for help): p
# Disk /dev/sdd: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
# Disk model: WD Blue SN570 1T
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 4096 bytes
# I/O size (minimum/optimal): 4096 bytes / 4096 bytes
# Disklabel type: gpt
# Disk identifier: 2003DD22-5B5C-C54F-B345-7431D3C71251

# Device      Start       End   Sectors  Size Type
# /dev/sdd1    2048    411647    409600  200M EFI System
# /dev/sdd2  411648    821247    409600  200M Linux filesystem
# /dev/sdd3  821248 105678847 104857600   50G Linux filesystem

# Command (m for help): w
# The partition table has been altered.
# Calling ioctl() to re-read partition table.
# Syncing disks.

# If you are prompted with the following message when creating a partition, you should remove the signature
# Created a new partition 1 of type 'Linux filesystem' and of size 200 MiB.
# Partition #1 contains a vfat signature.

# Do you want to remove the signature? [Y]es/[N]o: Y


# 2.5, replace <x>
# EFI partition
mkfs.vfat /dev/sd<x>1
# Boot partition
mkfs -v -t ext4 /dev/sd<x>2
# Root partition
mkfs -v -t ext4 /dev/sd<x>3


# 2.6
export LFS=/mnt/lfs
echo -e "\nexport LFS=/mnt/lfs\n" >> .bashrc
echo $LFS


# 2.7, replace <x>
mkdir -pv $LFS
mount -v -t ext4 /dev/sd<x>3 $LFS
mkdir -v $LFS/boot
mount -v -t ext4 /dev/sd<x>2 $LFS/boot

