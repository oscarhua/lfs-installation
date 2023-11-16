# Preparation
Titles contain links to specific chapters of the LFS book if applicable.

## 2.2. [Preparing the Host System](https://www.linuxfromscratch.org/lfs/view/12.0/chapter02/hostreqs.html)
Here I only show what I run.
```bash
apt update
apt upgrade -y
apt install -y bison gcc g++ m4 make texinfo fdisk
ln -sf bash /bin/sh

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
```


## 2.4. [Creating a New Partition](https://www.linuxfromscratch.org/lfs/view/12.0/chapter02/creatingpartition.html)
I choose to boot the system with UEFI, so I select GTP partition table and use the following partition:
| Number | Name | Path | Size | Type |
|:--:|:--:|:--:|:--:|:--:|
| 1 | EFI Partition  | /boot/efi | 200M | EFI System       |
| 2 | Boot Partition | /boot     | 200M | Linux filesystem |
| 3 | Root Partition | /         | 50G  | Linux filesystem |

First, use `lsblk` to find the disk drive you want to use.
```bash
$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0 363.3M  1 disk 
sdb      8:16   0     2G  0 disk [SWAP]
sdc      8:32   0     1T  0 disk /snap
                                 /mnt/wslg/distro
                                 /
sdd      8:48   0 931.5G  0 disk
```
In my case, the 1T hard drive named `sdd` is the one that I want to use. The full path to it is `/dev/sdd`. Start `fdisk /dev/sd<x>` to create a new partition. Replace `<x>` with the name your desired disk. This hard drive will be formatted, please back up any important data.

Commands needed in the `fdisk`
* `q` - quit without saving changes. **If any problem occurs and you don't want to write any changes to the hard drive, use this command**
* `g` - create a new empty GPT partition table.
* `n` - add a new partition
* `t` - change a partition type. Needed by EFI Partition
* `p` - print the partition table
* `w` - write table to disk and exit

If you see any prompt message saying "Do you want to remove the signature?", select Yes.

<pre><code class="language-bash">$ fdisk /dev/sd&lt;x&gt;
Welcome to fdisk (util-linux 2.37.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.


Command (m for help): <b>g</b>
Created a new GPT disklabel (GUID: 2003DD22-5B5C-C54F-B345-7431D3C71251).

Command (m for help): <b>n</b>
Partition number (1-128, default 1): 
First sector (2048-1953525134, default 2048): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-1953525134, default 1953525134): <b>+200M</b>

Created a new partition 1 of type 'Linux filesystem' and of size 200 MiB.

Command (m for help): <b>n</b>
Partition number (2-128, default 2): 
First sector (411648-1953525134, default 411648): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (411648-1953525134, default 1953525134): <b>+200M</b>

Created a new partition 2 of type 'Linux filesystem' and of size 200 MiB.

Command (m for help): <b>n</b>
Partition number (3-128, default 3): 
First sector (821248-1953525134, default 821248): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (821248-1953525134, default 1953525134): <b>+50G</b>

Created a new partition 3 of type 'Linux filesystem' and of size 50 GiB.

Command (m for help): <b>t</b>
Partition number (1-3, default 3): <b>1</b>
Partition type or alias (type L to list all): <b>uefi</b>

Changed type of partition 'Linux filesystem' to 'EFI System'.

Command (m for help): <b>p</b>
Disk /dev/sdd: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
Disk model: WD Blue SN570 1T
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: <b>gpt</b>
Disk identifier: 2003DD22-5B5C-C54F-B345-7431D3C71251

Device      Start       End   Sectors  Size Type
/dev/sdd1    2048    411647    409600  <b>200M</b> <b>EFI System</b>
/dev/sdd2  411648    821247    409600  <b>200M Linux</b> <b>filesystem</b>
/dev/sdd3  821248 105678847 104857600   <b>50G</b> <b>Linux filesystem</b>

Command (m for help): <b>w</b>
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
</code></pre>


## 2.5. [Creating a File System on the Partition](https://www.linuxfromscratch.org/lfs/view/12.0/chapter02/creatingfilesystem.html)
Run the following command to create `vfat` file system on EFI Partiton and `ext4` file systems on Boot Partition and Root Partition. Replace `<x>` with the name of your disk drive.
```bash
mkfs.vfat /dev/sd<x>1
mkfs -v -t ext4 /dev/sd<x>2
mkfs -v -t ext4 /dev/sd<x>3
```

## 2.6. [Setting The $LFS Variable](https://www.linuxfromscratch.org/lfs/view/12.0/chapter02/aboutlfs.html)
```bash
export LFS=/mnt/lfs
echo -e "\nexport LFS=/mnt/lfs\n" >> .bashrc
# From chapter 4.4.
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
echo $LFS
```
Note: In wsl, `/etc/profile`, `/etc/bash.bashrc`, `~/.bash_profile` is executed for login shell and `/etc/bash.bashrc`, `~/.bashrc` is executed for non-login shell.


## 2.7. [Mounting the New Partition](https://www.linuxfromscratch.org/lfs/view/12.0/chapter02/mounting.html)
Also, replace the `<x>` with the name of your disk drive.
```bash
mkdir -pv $LFS
mount -v -t ext4 /dev/sd<x>3 $LFS
mkdir -pv $LFS/boot
mount -v -t ext4 /dev/sd<x>2 $LFS/boot
```


# Installation
## Chapter 3 ~ 8
The process of compiling and installing packages is relatively tedious, and it can be completed through scripts. There are a few points that needed to be explained:
- The script just puts the commands from the book together and adds a little bit of modification to automate it. It will start over every time is is run and can't resume where you left. To be conservative, **5 hours** is enough to run the script in one go.
- The "set -e" is run at the beginning of each script to exit immediately on error. However, some really important tests are known to fail. I choose to ignore the errors and redirect the output to a file. Regardless of whether the script completes normally or not, these files should be compared with the results provided by [LFS](https://www.linuxfromscratch.org/lfs/build-logs/12.0/). (Select the CPU most similar to yours, then test-logs, then chapter name.) They are
    - $LFS/sources/glibc.check
    - $LFS/sources/binutils.check
    - $LFS/sources/gmp.check
    - $LFS/sources/gcc.check
    - [$LFS/sources/gcc.check2](https://www.linuxfromscratch.org/lfs/view/12.0/chapter08/gcc.html)
    - [$LFS/sources/glib.check](https://www.linuxfromscratch.org/blfs/view/12.0/general/glib2.html)
- If an error occurs or you want to build LFS in stages, please read the **2.3. Building LFS in Stages** carefully. After changing the script files, please go through the script flow and make sure that the requirements in the book are met.
- Chapter `7.13.2. Backup` is skipped. Chapter `8.62. GRUB-2.06` is replaced with its BLFS version. Chapter `8.82. Stripping` is done. Additional packages from BLFS are installed to improve basic functions. They include networking programs, `git`, firmware tools and file systems. The dependencies are described in `./part5.sh`.

As the `root` user, run
```bash
./part2.sh
```

# Configuration
Configuration is a highly subjective topic. Here I only explain in detail the parts that I think need to be customized. Things that I think are common and will not change in most cases are put in the script `$LFS/sources/part6.sh`.

Before configuring, please make sure
- The LFS environment variable is set for root
```bash
$ echo $LFS
/mnt/lfs
```
- The /mnt/lfs partition is mounted
```bash
$ ls $LFS
bin boot dev etc home .......
```
- The virtual file systems are mounted
```bash
$ findmnt | grep $LFS
└─/mnt/lfs                    /dev/sdd3        ext4          rw,relatime
  ├─/mnt/lfs/boot             /dev/sdd2        ext4          rw,relatime
  ├─/mnt/lfs/dev              none             devtmpfs      rw,nosuid,...
  │ ├─/mnt/lfs/dev/pts        devpts           devpts        rw,nosuid,...
  │ └─/mnt/lfs/dev/shm        tmpfs            tmpfs         rw,nosuid,...
  ├─/mnt/lfs/proc             proc             proc          rw,relatime
  ├─/mnt/lfs/sys              sysfs            sysfs         rw,relatime
  └─/mnt/lfs/run              tmpfs            tmpfs         rw,relatime
```
If the system is built in one session, the above requirements are met by default. If there are any problems, please check [2.7. Mounting the New Partition](https://www.linuxfromscratch.org/lfs/view/12.0/chapter02/mounting.html), [2.6. Setting The $LFS Variable](https://www.linuxfromscratch.org/lfs/view/12.0/chapter02/aboutlfs.html), [7.3. Preparing Virtual Kernel File Systems](https://www.linuxfromscratch.org/lfs/view/12.0/chapter07/kernfs.html)

## Entering the Chroot Environment
```bash
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login
```

## Cofiguration done with script
- [9.5. General Network Configuration](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/network.html) excluding hostname and dns
- [9.6. System V Bootscript Usage and Configuration](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/usage.html)
- [The Bash Shell Startup Files](https://www.linuxfromscratch.org/blfs/view/12.0/postlfs/profile.html) in BLFS
- [9.8. Creating the /etc/inputrc File](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/inputrc.html)
- [9.9. Creating the /etc/shells File](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/etcshells.html)

Run
```bash
/bin/bash /sources/part6.sh
```


## 8.5.2.2. [Adding Time Zone Data](https://www.linuxfromscratch.org/lfs/view/12.0/chapter08/glibc.html)
After running
```bash
tzselect
ln -sfv /usr/share/zoneinfo/<xxx> /etc/localtime
```
you can check whether the setting is successful by running `date`.

## 8.26.3. [Setting the Root Password](https://www.linuxfromscratch.org/lfs/view/12.0/chapter08/shadow.html)
Choose a password for user root and set it by running:
```bash
passwd root
```

## 9.5.2. [Creating the /etc/resolv.conf File](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/network.html)
The following is one possible configuration if FQDN is not applicable.
```bash
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

nameserver 8.8.8.8
nameserver 8.8.4.4

# End /etc/resolv.conf
EOF
```

## 9.5.3. [Configuring the System Hostname]((https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/network.html))
Run the following command. `<lfs>` needs to be replaced with the name given to the computer.
```bash
echo "<lfs>" > /etc/hostname
```

## Language, Keymap and Font
Refer to [9.7. The Bash Shell Startup Files](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/profile.html) and [9.6.5. Configuring the Linux Console](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/usage.html). Note that the results of 9.7 should be placed in **/etc/profile.d/i18n.sh** instead of /etc/profile, which is BLFS standard. For English and U.S. keyboard, the following is one possible configuration.
```bash
# 9.7
cat > /etc/profile.d/i18n.sh << "EOF"
# Set up i18n variables
export LANG=en_US.utf8
EOF

# 9.6.5
cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

UNICODE="1"

# End /etc/sysconfig/console
EOF
```

## 10.3. [Linux-6.4.12](https://www.linuxfromscratch.org/lfs/view/12.0/chapter10/kernel.html)
Run
```bash
cd /sources
tar -xf linux-6.4.12.tar.xz
cd linux-6.4.12
make mrproper
make defconfig
make menuconfig
```

Sources of required features
- [10.3. Linux-6.4.12](https://www.linuxfromscratch.org/lfs/view/12.0/chapter10/kernel.html)
- [Using GRUB to Set Up the Boot Process with UEFI](https://www.linuxfromscratch.org/blfs/view/12.0/postlfs/grub-setup.html)
- [About Firmware](https://www.linuxfromscratch.org/blfs/view/12.0/postlfs/firmware.html)
- [dosfstools](https://www.linuxfromscratch.org/blfs/view/12.0/postlfs/dosfstools.html)
- [Configuring the Linux Kernel for Wireless](https://www.linuxfromscratch.org/blfs/view/12.0/basicnet/wireless-kernel.html)
- [Wireless Tools](https://www.linuxfromscratch.org/blfs/view/12.0/basicnet/wireless_tools.html)
- [USB Support](https://github.com/dorssel/usbipd-win/wiki/WSL-support#building-your-own-usbip-enabled-wsl-2-kernel)
- [bridge-utils](https://www.linuxfromscratch.org/blfs/view/12.0/basicnet/bridge-utils.html)

Required features arranged in the order of menuconfig
```
General setup --->
  [ ] Compile the kernel with warnings as errors                        [WERROR]
  CPU/Task time and stats accounting --->
    [*] Pressure stall information tracking                                [PSI]
    [ ]   Require boot parameter to enable pressure stall information tracking
                                                     ...  [PSI_DEFAULT_DISABLED]
  < > Enable kernel headers through /sys/kernel/kheaders.tar.xz      [IKHEADERS]
  [*] Control Group support --->                                       [CGROUPS]
    [*] Memory controller                                                [MEMCG]
  [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
                                                           ...  [BLK_DEV_INITRD]
  [ ] Configure standard kernel features (expert users) --->            [EXPERT]

Processor type and features --->
  [*] Support x2apic                                                [X86_X2APIC]
  [*] CPU microcode loading support                                  [MICROCODE]
  [*]   Intel microcode loading support                        [MICROCODE_INTEL]
  [*]   AMD microcode loading support                            [MICROCODE_AMD]
  [*] EFI runtime service support                                          [EFI]
  [*] Build a relocatable kernel                                   [RELOCATABLE]
  [*]   Randomize the address of the kernel image (KASLR)       [RANDOMIZE_BASE]

General architecture-dependent options --->
  [*] Stack Protector buffer overflow detection                 [STACKPROTECTOR]
  [*]   Strong Stack Protector                           [STACKPROTECTOR_STRONG]

-*- Enable the block layer --->                                          [BLOCK]
  Partition Types --->
    [*] Advanced partition selection                        [PARTITION_ADVANCED]
    [*]     EFI GUID Partition support                           [EFI_PARTITION]

[*] Networking support --->                                                [NET]
  Networking options --->
    <*/M> 802.1d Ethernet Bridging                                      [BRIDGE]
  [*] Wireless --->                                                   [WIRELESS]
    <*/M> cfg80211 - wireless configuration API                       [CFG80211]
    [*]     cfg80211 wireless extensions compatibility           [CFG80211_WEXT]
    < /*/M> Generic IEEE 802.11 Networking Stack (mac80211)           [MAC80211]

Device Drivers --->
  [*] PCI support --->                                                     [PCI]
    [*] Message Signaled Interrupts (MSI and MSI-X)                    [PCI_MSI]
  Generic Driver Options --->
    [ ] Support for uevent helper                                [UEVENT_HELPER]
    [*] Maintain a devtmpfs filesystem to mount at /dev               [DEVTMPFS]
    [*]   Automount devtmpfs at /dev, after the kernel mounted the rootfs
                                                           ...  [DEVTMPFS_MOUNT]
  Firmware Drivers --->
    [*] Mark VGA/VBE/EFI FB as generic system framebuffer       [SYSFB_SIMPLEFB]
  NVME Support --->
    <*> NVM Express block device                                  [BLK_DEV_NVME]
  [*] Network device support --->                                   [NETDEVICES]
    [*] Wireless LAN --->                                                 [WLAN]
  Graphics support --->
    <*> Direct Rendering Manager (XFree86 4.1.0 and higher DRI support) --->
                                                                      ...  [DRM]
    [*] Enable legacy fbdev support for your modesetting driver
                                                      ...  [DRM_FBDEV_EMULATION]
    <*> Simple framebuffer driver                                [DRM_SIMPLEDRM]
    Frame buffer Devices --->
      <*> Support for frame buffer devices --->                             [FB]
    Console display driver support --->
      [*] Framebuffer Console support                      [FRAMEBUFFER_CONSOLE]
  [*] USB support --->                                             [USB_SUPPORT]
    [*] USB announce new devices                      [USB_ANNOUNCE_NEW_DEVICES]
    <*> USB Modem (CDC ACM) support                                    [USB_ACM]
    <*> USB Serial Converter support --->                           [USB_SERIAL]
      <*> USB FTDI Single Port Serial Driver               [USB_SERIAL_FTDI_SIO]
  [*] IOMMU Hardware Support --->                                [IOMMU_SUPPORT]
    [*] Support for Interrupt Remapping                              [IRQ_REMAP]

File systems --->
  DOS/FAT/EXFAT/NT Filesystems --->
    < /*/M> MSDOS fs support                                          [MSDOS_FS]
    <*/M> VFAT (Windows-95) fs support                                 [VFAT_FS]
  Pseudo filesystems --->
    <*/M> EFI Variable filesystem                                    [EFIVAR_FS]
  -*- Native language support --->                                         [NLS]
    <*/M> Codepage 437 (United States, Canada)                [NLS_CODEPAGE_437]
    <*/M> NLS ISO 8859-1  (Latin 1; Western European Languages)  [NLS_ISO8859_1]
```
If you are building a 32-bit system running on a hardware with RAM more than 4GB, adjust the configuration so the kernel will be able to use up to 64GB physical RAM.
```
Processor type and features --->
  High Memory Support --->
    (X) 64GB                                                        [HIGHMEM64G]
```
Run the following commands to install kernel and configure linux module load order. Replace `<N>` with the number of processors, and replace `<arch>` with the architecture of the CPU (which can be determined by running `uname -m`).
```bash
make -j<N>
make modules_install
cp -iv arch/<arch>/boot/bzImage /boot/vmlinuz-6.4.12-lfs-12.0
cp -iv System.map /boot/System.map-6.4.12
cp -iv .config /boot/config-6.4.12
cp -r Documentation -T /usr/share/doc/linux-6.4.12

install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

cd ..
chown -R 0:0 linux-6.4.12
``` 

## /etc/fstab and GRUB configuration
I will rearrange the useful information which is scattered across
- [10.2. Creating the /etc/fstab File](https://www.linuxfromscratch.org/lfs/view/12.0/chapter10/fstab.html)
- [10.4. Using GRUB to Set Up the Boot Process](https://www.linuxfromscratch.org/lfs/view/12.0/chapter10/grub.html)
- [Using GRUB to Set Up the Boot Process with UEFI](https://www.linuxfromscratch.org/blfs/view/12.0/postlfs/grub-setup.html)

First, get the UUID of partition and UUID of filesystem for EFI Partition, Boot Partition and Root Partition. Replace `<x>` with the name of your disk drive
```bash
$ blkid /dev/sd<x>*
/dev/sdd: PTUUID="ca7fac9e-701c-cd49-8075-fb88000d349a" PTTYPE="gpt"
/dev/sdd1: SEC_TYPE="msdos" UUID="6540-AF2B" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="c666225c-9411-be4f-8935-1030be43066e"
/dev/sdd2: UUID="63529a30-e59a-475e-8f64-458081118fa4" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="e3f79a01-9a4e-5f4c-9019-5a0ddf7d1b03"
/dev/sdd3: UUID="85e2dd13-4a20-4e11-9983-4d106e24ca98" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="9a8b99bb-e408-6d4b-ba7e-18394c565f3e"
```
**Warning: All subsequent commands are very dangerous and may render the host system completely unusable. Check one last time that the shell is running in the chroot environmnet and the name of target hard disk for installing lfs is correct.**

Then, create the /etc/fstab file. Fill in the PARTUUID value obtained previously.
```bash
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order

PARTUUID=<PARTUUID of sdx3>  /          ext4  defaults           1  1
PARTUUID=<PARTUUID of sdx2>  /boot      ext4  defaults           1  2
PARTUUID=<PARTUUID of sdx1>  /boot/efi  vfat  codepage=437,utf8  1  2
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF
```
In my case, it is
```bash
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order

PARTUUID=9a8b99bb-e408-6d4b-ba7e-18394c565f3e  /          ext4  defaults           1  1
PARTUUID=e3f79a01-9a4e-5f4c-9019-5a0ddf7d1b03  /boot      ext4  defaults           1  2
PARTUUID=c666225c-9411-be4f-8935-1030be43066e  /boot/efi  vfat  codepage=437,utf8  1  2
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF
```
Use GRUB to set up the boot process with UEFI. Replace `<x>` with the name of your hard drive.
```bash
mount --mkdir -v -t vfat /dev/sd<x>1 -o codepage=437,utf8 /boot/efi
grub-install --target=x86_64-efi --removable
```
Create the GRUB configuration file. Fill in the corresponding UUID or PARTUUID values according to the description.
```bash
cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2
search --set=root --fs-uuid <UUID of sdx2>

insmod all_video
if loadfont /grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, Linux 6.4.10-lfs-12.0"  {
  linux   /vmlinuz-6.4.12-lfs-12.0 root=PARTUUID=<PARTUUID of sdx3> ro
}

menuentry "Firmware Setup" {
  fwsetup
}
EOF
```
In my case, it is
```bash
cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2
search --set=root --fs-uuid 63529a30-e59a-475e-8f64-458081118fa4

insmod all_video
if loadfont /grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, Linux 6.4.12-lfs-12.0"  {
  linux   /vmlinuz-6.4.12-lfs-12.0 root=PARTUUID=9a8b99bb-e408-6d4b-ba7e-18394c565f3e ro
}

menuentry "Firmware Setup" {
  fwsetup
}
EOF
```

## [Microcode updates for CPUs](https://www.linuxfromscratch.org/blfs/view/12.0/postlfs/firmware.html)
Here I only show the complete process of installing microcode for my computer. The required kernel configurations have been done previously for both Intel and AMD.
```bash
# Check what processor I have
$ head -n7 /proc/cpuinfo
processor       : 0
vendor_id       : GenuineIntel
cpu family      : 6
model           : 165
model name      : Intel(R) Core(TM) i7-10875H CPU @ 2.30GHz
stepping        : 2
microcode       : 0xffffffff

# Download the Intel Microcode
cd /sources
wget https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/archive/refs/tags/microcode-20230808.tar.gz
tar -xf microcode-20230808.tar.gz
cd Intel-Linux-Processor-Microcode-Data-Files-microcode-20230808

# Early loading of microcode, where XX=cpu-family=06, YY=model=a5, ZZ=stepping=02
mkdir -p initrd/kernel/x86/microcode
cd initrd
cp -v ../intel-ucode/06-a5-02 kernel/x86/microcode/GenuineIntel.bin
find . | cpio -o -H newc > /boot/microcode.img

# Add a new line "initrd /microcode.img" to /boot/grub/grub.cfg after the linux line within the stanza.
sed -i '/vmlinuz-6.4.12-lfs-12.0/a \  initrd  /microcode.img' /boot/grub/grub.cfg

# Exit
cd ../..
rm -rf Intel-Linux-Processor-Microcode-Data-Files-microcode-20230808
```

## 11.1. [The End](https://www.linuxfromscratch.org/lfs/view/12.0/chapter11/theend.html)
Customize the fields "DISTRIB_CODENAME" and "VERSION_CODENAME"
```bash
echo 12.0 > /etc/lfs-release

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="12.0"
DISTRIB_CODENAME="<your name here>"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="12.0"
ID=lfs
PRETTY_NAME="Linux From Scratch 12.0"
VERSION_CODENAME="<your name here>"
EOF
```
Well done! The LFS system is installed and bootable. Some commands in later chapters may need to be performed after rebooting into the system. Before rebooting, you need to run
```bash
# Exit from the chroot environment
logout

# unmount the virtual file systems 
umount -v $LFS/dev/pts
mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys
# unmount lfs partitions
umount -v $LFS/{boot,}

# Now you can reboot into the LFS system
```


## [Device and Module Handling](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/udev.html)
Use `lspci -v` to display information about all PCI buses in the system and all devices connected to them. Here I only use the wireless network adapter of my computer as an example.
```bash
$ lspci -v
......
00:14.3 Network controller: Intel Corporation Comet Lake PCH CNVi WiFi
	Subsystem: Intel Corporation Wi-Fi 6 AX201 160MHz
	Flags: bus master, fast devsel, latency 0, IRQ 255
	Memory at c2598000 (64-bit, non-prefetchable) [size=16K]
	Capabilities: [c8] Power Management version 3
	Capabilities: [d0] MSI: Enable- Count=1/1 Maskable- 64bit+
	Capabilities: [40] Express Root Complex Integrated Endpoint, MSI 00
	Capabilities: [80] MSI-X: Enable- Count=16 Masked-
	Capabilities: [100] Latency Tolerance Reporting
	Capabilities: [164] Vendor Specific Information: ID=0010 Rev=0 Len=014 <?>
......
```
After searching the Internet for support for this device, I find [Linux Support for Intel Wireless Adapters](https://www.intel.com/content/www/us/en/support/articles/000005511/wireless.html). My device is supported by the `iwlwifi` driver and the required firmware is [iwlwifi-Qu-48.13675109.0.tgz](https://wireless.wiki.kernel.org/_media/en/users/drivers/iwlwifi/iwlwifi-qu-48.13675109.0.tgz). Download it and follow the instructions in README. First, copy the files to firmware directory.
```bash
cd /sources
wget https://wireless.wiki.kernel.org/_media/en/users/drivers/iwlwifi/iwlwifi-qu-48.13675109.0.tgz
tar -xf iwlwifi-qu-48.13675109.0.tgz
cd iwlwifi-Qu-48.13675109.0
cp iwlwifi-Qu-*-48.ucode /lib/firmware
cd ..
rm -rf iwlwifi-Qu-48.13675109.0
```
Then, enable `iwlwifi` and `firmware loader` in the kernel configuration and rebuild the kernel.
```bash
cd /sources/linux-6.4.12
make mrproper
cp /boot/config-6.4.12 .config
make menuconfig

# Device Drivers --->
#   Generic Driver Options --->
#     Firmware loader --->
#       [*] Firmware loading facility                                  [FW_LOADER]
#         [*] Enable the firmware sysfs fallback mechanism [FW_LOADER_USER_HELPER]
#   [*] network device support --->                                   [NETDEVICES]
#     [*] Wireless LAN --->                                                 [WLAN]
#       [*] Intel devices                                      [WLAN_VENDOR_INTEL]
#       <M>   Intel Wireless WiFi Next Gen AGN -
#                             Wireless-N/Advanced-N/Ultimate-N (iwlwifi) [IWLWIFI]
#       <M>     Intel Wireless WiFi MVM Firmware support                  [IWLMVM]

make -j8
make modules_install
cp -iv arch/x86_64/boot/bzImage /boot/vmlinuz-6.4.12-lfs-12.0
cp -iv System.map /boot/System.map-6.4.12
cp -iv .config /boot/config-6.4.12
```
Configure wifi according to [wpa_supplicant](https://www.linuxfromscratch.org/blfs/view/12.0/basicnet/wpa_supplicant.html).
```bash
wpa_passphrase <SSID> <SECRET_PASSWORD> > /etc/sysconfig/wpa_supplicant-wlan0.conf

cat > /etc/sysconfig/ifconfig.wlan0 << "EOF"
ONBOOT="yes"
IFACE="wlan0"
SERVICE="wpa"

WPA_ARGS=""

WPA_SERVICE="dhcpcd"
DHCP_START="-b -q -h '' -C resolv.conf"
DHCP_STOP="-k"
EOF
```

## [Problems with Loading Modules and Creating Devices](https://www.linuxfromscratch.org/lfs/view/12.0/chapter09/udev.html)
I will continue to use the wireless network adapter of my computer as an example. First, get the PCI device address and check the `modalias` in `/sys/bus/pci/devices/0000:<address>`.
<pre><code class="language-bash">$ lspci -v
......
<b>00:14.3</b> Network controller: Intel Corporation Comet Lake PCH CNVi WiFi
	Subsystem: Intel Corporation Wi-Fi 6 AX201 160MHz
	Flags: bus master, fast devsel, latency 0, IRQ 255
	Memory at c2598000 (64-bit, non-prefetchable) [size=16K]
	Capabilities: [c8] Power Management version 3
	Capabilities: [d0] MSI: Enable- Count=1/1 Maskable- 64bit+
	Capabilities: [40] Express Root Complex Integrated Endpoint, MSI 00
	Capabilities: [80] MSI-X: Enable- Count=16 Masked-
	Capabilities: [100] Latency Tolerance Reporting
	Capabilities: [164] Vendor Specific Information: ID=0010 Rev=0 Len=014 <?>
......

# In my case the address of my wireless network adapter is 00:14.3
$ cd /sys/bus/pci/devices/0000:00:14.3
$ cat modalias
<b>pci:v00008086d000006F0sv00008086sd00000074bc02sc80i00</b>
</code></pre>
If there is no `modalias` file, this means that the kernel developers haven't yet added modalias support. Expect this issue to be fixed in later kernel versions. Next step is to check the module (driver).
<pre><code class="language-bash">$ lsmod
<b>iwlwifi</b>
</code></pre>
If the module is not loaded (e.g. if **iwlwifi** not found in my case), then it is a bug in the driver. Load the driver manually and expect the issue to be fixed later.
```bash
$ modprobe iwlwifi
```
If the device still doesn't work properly, check the output of the module in the kernel boot messages.
```bash
$ dmesg | grep iwlwifi
Nov  6 14:14:19 LAPTOP kernel: [2.621863] iwlwifi 0000:00:14.3: Detected crf-id 0x3617, cnv-id 0x20000302 wfpm id 0x80000000
Nov  6 14:14:19 LAPTOP kernel: [2.624370] iwlwifi 0000:00:14.3: PCI dev 06f0/0074, rev=0x351, rfid=0x10a100
Nov  6 14:14:19 LAPTOP kernel: [2.626998] iwlwifi 0000:00:14.3: Direct firmware load for iwlwifi-QuZ-a0-hr-b0-78.ucode failed with error -2
Nov  6 14:14:19 LAPTOP kernel: [2.627550] iwlwifi 0000:00:14.3: Direct firmware load for iwlwifi-QuZ-a0-hr-b0-77.ucode failed with error -2
......
Nov  6 14:14:19 LAPTOP kernel: [2.652865] iwlwifi 0000:00:14.3: Direct firmware load for iwlwifi-QuZ-a0-hr-b0-39.ucode failed with error -2
Nov  6 14:14:19 LAPTOP kernel: [2.653104] iwlwifi 0000:00:14.3: no suitable firmware found!
Nov  6 14:14:19 LAPTOP kernel: [2.653341] iwlwifi 0000:00:14.3: minimum version required: iwlwifi-QuZ-a0-hr-b0-39
Nov  6 14:14:19 LAPTOP kernel: [2.653649] iwlwifi 0000:00:14.3: maximum version supported: iwlwifi-QuZ-a0-hr-b0-78
Nov  6 14:14:19 LAPTOP kernel: [2.653890] iwlwifi 0000:00:14.3: check git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
```
In my case the firmware installed doesn't meet with the requirements. So go to the linux firmware git repo to download the firmware.
```bash
cd /lib/firmware
rm -rf iwlwifi-Qu-*-48.ucode
wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/iwlwifi-QuZ-a0-hr-b0-39.ucode
```
The problem is solved.
