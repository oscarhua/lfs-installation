# LFS Simplified Process
## References
- [**Linux From Scratch - 12.0**](https://www.linuxfromscratch.org/lfs/view/12.0/)
- [**Beyond Linux From Scratch-12.0**](https://www.linuxfromscratch.org/blfs/view/12.0/)

## Goals
The goal of this project is to provide a concrete and easy-to-follow tutorial for installing the LFS.

Completing the LFS book in its entirety is not an easy task. When I first read the book, the guide for Chapter 2.4 Creating a New Partition looked vague, and there was a bunch of codes in Chapter 9 System Configuration that I wasn't sure whether I should run it. This document faithfully records all the operations I performed as an example of installing LFS and successfully booting into the system. It only represents one possible interpretation of the book, and you may find things that need to change based on your understanding.

Learning in the process of building LFS is often more important than the final completed LFS system. Almost half of the book is about installing packages and repeating processes similar to `./configure && make && make check && make install`. This document hopes to focus on educational parts, allowing readers to spend their main effort on understanding the difficult contents in the book, such as creating /etc/fstab and /boot/grub/grub.cfg and managing devices. Therefore, this document uses scripts to complete the installation of packages and basic configuration files. The main parts are about important configurations that differ between systems.

## Prerequisites
This document is only supplementary material and should not be used in isolation from the book. You should have read the LFS book once and when in front of a shell you know at least know how to tell whether
- You are in chroot
- Virtual kernel file systems are mounted
- Root file system is mounted
- LFS variable is set

and know the correct enviornment for each command in LFS book.


## Enviornment
I used wsl to protect the real host system.
```
$ PS C:\WINDOWS\system32> wsl --version
WSL Version： 1.2.5.0
Kernel Version： 5.15.90.1
WSLg Version： 1.0.51
MSRDC Version： 1.2.3770
Direct3D Version： 1.608.2-61064218
DXCore Version： 10.0.25131.1002-220531-1700.rs-onecore-base2-hyp
Windows Version： 10.0.19045.3693
```
```
$ root@LAPTOP:~# lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.3 LTS
Release:        22.04
Codename:       jammy
$ root@LAPTOP:~# uname -a
Linux LAPTOP 5.15.90.1-microsoft-standard-WSL2 #1 SMP Mon Sep 11 14:40:31 EDT 2023 x86_64 x86_64 x86_64 GNU/Linux
```

## Start from [here](tutorial.md)
