#!/bin/bash
set -e

# Check files
if [ ! -e "part3.sh" ] || [ ! -e "part4.sh" ] || [ ! -e "part5.sh" ] || [ ! -e "part6.sh" ] || [ ! -e "version-check.sh" ]; then
    echo "Script files missing. Expect ./part3.sh, ./part4.sh, ./part5.sh ./part6.sh ./version-check.sh"
    exit 1
fi
# Check user
if [ $EUID -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi
# Check version
/bin/bash ./version-check.sh
# Check $LFS
if [ "$LFS" != "/mnt/lfs" ]; then
    echo "The LFS enviornment varialbe is not set to /mnt/lfs."
    exit 1
fi
# Check contents of $LFS/
if [ $(ls $LFS | wc -l) -ne 1 ] ||  [ ! -e $LFS/boot ]; then
    echo "The $LFS directory is not empty or boot partition is not mounted."
    exit 1
fi
# Remove everything except $LFS/boot, which is a mountpoint
# rm -rf $LFS/{bin,dev,etc,home,lib,lib64,media,mnt,opt,proc,root,run,sbin,sources,srv,sys,tmp,usr,var}

# 3.1
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

cat > wget-list-sysv << "EOF"
https://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz
https://download.savannah.gnu.org/releases/attr/attr-2.5.1.tar.gz
https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.xz
https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.xz
https://ftp.gnu.org/gnu/bash/bash-5.2.15.tar.gz
https://github.com/gavinhoward/bc/releases/download/6.6.0/bc-6.6.0.tar.xz
https://sourceware.org/pub/binutils/releases/binutils-2.41.tar.xz
https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz
https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz
https://ftp.gnu.org/gnu/coreutils/coreutils-9.3.tar.xz
https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz
https://ftp.gnu.org/gnu/diffutils/diffutils-3.10.tar.xz
https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.0/e2fsprogs-1.47.0.tar.gz
https://sourceware.org/ftp/elfutils/0.189/elfutils-0.189.tar.bz2
https://prdownloads.sourceforge.net/expat/expat-2.5.0.tar.xz
https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz
https://astron.com/pub/file/file-5.45.tar.gz
https://ftp.gnu.org/gnu/findutils/findutils-4.9.0.tar.xz
https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
https://pypi.org/packages/source/f/flit-core/flit_core-3.9.0.tar.gz
https://ftp.gnu.org/gnu/gawk/gawk-5.2.2.tar.xz
https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz
https://ftp.gnu.org/gnu/gdbm/gdbm-1.23.tar.gz
https://ftp.gnu.org/gnu/gettext/gettext-0.22.tar.xz
https://ftp.gnu.org/gnu/glibc/glibc-2.38.tar.xz
https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz
https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz
https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz
https://ftp.gnu.org/gnu/grub/grub-2.06.tar.xz
https://ftp.gnu.org/gnu/gzip/gzip-1.12.tar.xz
https://github.com/Mic92/iana-etc/releases/download/20230810/iana-etc-20230810.tar.gz
https://ftp.gnu.org/gnu/inetutils/inetutils-2.4.tar.xz
https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz
https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.4.0.tar.xz
https://pypi.org/packages/source/J/Jinja2/Jinja2-3.1.2.tar.gz
https://www.kernel.org/pub/linux/utils/kbd/kbd-2.6.1.tar.xz
https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-30.tar.xz
https://www.greenwoodsoftware.com/less/less-643.tar.gz
https://www.linuxfromscratch.org/lfs/downloads/12.0/lfs-bootscripts-20230728.tar.xz
https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.69.tar.xz
https://github.com/libffi/libffi/releases/download/v3.4.4/libffi-3.4.4.tar.gz
https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.7.tar.gz
https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.xz
https://github.com/besser82/libxcrypt/releases/download/v4.4.36/libxcrypt-4.4.36.tar.xz
https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.4.12.tar.xz
https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz
https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
https://download.savannah.gnu.org/releases/man-db/man-db-2.11.2.tar.xz
https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.05.01.tar.xz
https://pypi.org/packages/source/M/MarkupSafe/MarkupSafe-2.1.3.tar.gz
https://github.com/mesonbuild/meson/releases/download/1.2.1/meson-1.2.1.tar.gz
https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.0.tar.xz
https://invisible-mirror.net/archives/ncurses/ncurses-6.4.tar.gz
https://github.com/ninja-build/ninja/archive/v1.11.1/ninja-1.11.1.tar.gz
https://www.openssl.org/source/openssl-3.1.2.tar.gz
https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
https://www.cpan.org/src/5.0/perl-5.38.0.tar.xz
https://distfiles.ariadne.space/pkgconf/pkgconf-2.0.1.tar.xz
https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.3.tar.xz
https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.6.tar.xz
https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tar.xz
https://www.python.org/ftp/python/doc/3.11.4/python-3.11.4-docs-html.tar.bz2
https://ftp.gnu.org/gnu/readline/readline-8.2.tar.gz
https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz
https://github.com/shadow-maint/shadow/releases/download/4.13/shadow-4.13.tar.xz
https://www.infodrom.org/projects/sysklogd/download/sysklogd-1.5.1.tar.gz
https://github.com/systemd/systemd/archive/v254/systemd-254.tar.gz
https://anduin.linuxfromscratch.org/LFS/systemd-man-pages-254.tar.xz
https://github.com/slicer69/sysvinit/releases/download/3.07/sysvinit-3.07.tar.xz
https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz
https://downloads.sourceforge.net/tcl/tcl8.6.13-src.tar.gz
https://downloads.sourceforge.net/tcl/tcl8.6.13-html.tar.gz
https://ftp.gnu.org/gnu/texinfo/texinfo-7.0.3.tar.xz
https://www.iana.org/time-zones/repository/releases/tzdata2023c.tar.gz
https://anduin.linuxfromscratch.org/LFS/udev-lfs-20230818.tar.xz
https://www.kernel.org/pub/linux/utils/util-linux/v2.39/util-linux-2.39.1.tar.xz
https://anduin.linuxfromscratch.org/LFS/vim-9.0.1677.tar.gz
https://pypi.org/packages/source/w/wheel/wheel-0.41.1.tar.gz
https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.46.tar.gz
https://tukaani.org/xz/xz-5.4.4.tar.xz
https://anduin.linuxfromscratch.org/LFS/zlib-1.2.13.tar.xz
https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz
https://www.linuxfromscratch.org/patches/lfs/12.0/bzip2-1.0.8-install_docs-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.0/coreutils-9.3-i18n-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.0/glibc-2.38-memalign_fix-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.0/glibc-2.38-fhs-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.0/grub-2.06-upstream_fixes-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.0/kbd-2.6.1-backspace-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.0/readline-8.2-upstream_fix-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.0/sysvinit-3.07-consolidated-1.patch
EOF

wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources

cat > $LFS/sources/md5sums << "EOF"
95ce715fe09acca7c12d3306d0f076b2  acl-2.3.1.tar.xz
ac1c5a7a084f0f83b8cace34211f64d8  attr-2.5.1.tar.gz
12cfa1687ffa2606337efe1a64416106  autoconf-2.71.tar.xz
4017e96f89fca45ca946f1c5db6be714  automake-1.16.5.tar.xz
4281bb43497f3905a308430a8d6a30a5  bash-5.2.15.tar.gz
a148cbaaf8ff813b7289a00539e74a5f  bc-6.6.0.tar.xz
256d7e0ad998e423030c84483a7c1e30  binutils-2.41.tar.xz
c28f119f405a2304ff0a7ccdcc629713  bison-3.8.2.tar.xz
67e051268d0c475ea773822f7500d0e5  bzip2-1.0.8.tar.gz
50fcafcecde5a380415b12e9c574e0b2  check-0.15.2.tar.gz
040b4b7acaf89499834bfc79609af29f  coreutils-9.3.tar.xz
68c5208c58236eba447d7d6d1326b821  dejagnu-1.6.3.tar.gz
2745c50f6f4e395e7b7d52f902d075bf  diffutils-3.10.tar.xz
6b4f18a33873623041857b4963641ee9  e2fsprogs-1.47.0.tar.gz
5cfaa711a90cb670406cd495aeaa6030  elfutils-0.189.tar.bz2
ac6677b6d1b95d209ab697ce8b688704  expat-2.5.0.tar.xz
00fce8de158422f5ccd2666512329bd2  expect5.45.4.tar.gz
26b2a96d4e3a8938827a1e572afd527a  file-5.45.tar.gz
4a4a547e888a944b2f3af31d789a1137  findutils-4.9.0.tar.xz
2882e3179748cc9f9c23ec593d6adc8d  flex-2.6.4.tar.gz
3bc52f1952b9a78361114147da63c35b  flit_core-3.9.0.tar.gz
d63b4de2c722cbd9b8cc8e6f14d78a1e  gawk-5.2.2.tar.xz
e0e48554cc6e4f261d55ddee9ab69075  gcc-13.2.0.tar.xz
8551961e36bf8c70b7500d255d3658ec  gdbm-1.23.tar.gz
db2f3daf34fd5b85ab1a56f9033e42d1  gettext-0.22.tar.xz
778cce0ea6bf7f84ca8caacf4a01f45b  glibc-2.38.tar.xz
956dc04e864001a9c22429f761f2c283  gmp-6.3.0.tar.xz
9e251c0a618ad0824b51117d5d9db87e  gperf-3.1.tar.gz
7c9bbd74492131245f7cdb291fa142c0  grep-3.11.tar.xz
5e4f40315a22bb8a158748e7d5094c7d  groff-1.23.0.tar.gz
cf0fd928b1e5479c8108ee52cb114363  grub-2.06.tar.xz
9608e4ac5f061b2a6479dc44e917a5db  gzip-1.12.tar.xz
0502bd41cc0bf1c1c3cd8651058b9650  iana-etc-20230810.tar.gz
319d65bb5a6f1847c4810651f3b4ba74  inetutils-2.4.tar.xz
12e517cac2b57a0121cda351570f1e63  intltool-0.51.0.tar.gz
90ce0eb84a8f1e2b14ffa77e8eb3f5ed  iproute2-6.4.0.tar.xz
d31148abd89c1df1cdb077a55db27d02  Jinja2-3.1.2.tar.gz
986241b5d94c6bd4ed2f6d2a5ab4320b  kbd-2.6.1.tar.xz
85202f0740a75eb52f2163c776f9b564  kmod-30.tar.xz
cf05e2546a3729492b944b4874dd43dd  less-643.tar.gz
740e56f1f2448766b672c53ae3abb5c2  lfs-bootscripts-20230728.tar.xz
4667bacb837f9ac4adb4a1a0266f4b65  libcap-2.69.tar.xz
0da1a5ed7786ac12dcbaf0d499d8a049  libffi-3.4.4.tar.gz
1a48b5771b9f6c790fb4efdb1ac71342  libpipeline-1.5.7.tar.gz
2fc0b6ddcd66a89ed6e45db28fa44232  libtool-2.4.7.tar.xz
b84cd4104e08c975063ec6c4d0372446  libxcrypt-4.4.36.tar.xz
24570ba0ef9dd592bd640a1a41686fac  linux-6.4.12.tar.xz
0d90823e1426f1da2fd872df0311298d  m4-1.4.19.tar.xz
c8469a3713cbbe04d955d4ae4be23eeb  make-4.4.1.tar.gz
a7d59fb2df6158c44f8f7009dcc6d875  man-db-2.11.2.tar.xz
de4563b797cf9b1e0b0d73628b35e442  man-pages-6.05.01.tar.xz
ca33f119bd0551ce15837f58bb180214  MarkupSafe-2.1.3.tar.gz
e3cc846536189aacd7d01858a45ca9af  meson-1.2.1.tar.gz
5c9bc658c9fd0f940e8e3e0f09530c62  mpc-1.3.1.tar.gz
a25091f337f25830c16d2054d74b5af7  mpfr-4.2.0.tar.xz
5a62487b5d4ac6b132fe2bf9f8fad29b  ncurses-6.4.tar.gz
32151c08211d7ca3c1d832064f6939b0  ninja-1.11.1.tar.gz
1d7861f969505e67b8677e205afd9ff4  openssl-3.1.2.tar.gz
78ad9937e4caadcba1526ef1853730d5  patch-2.7.6.tar.xz
e1c8aaec897dd386c741f97eef9f2e87  perl-5.38.0.tar.xz
efc1318f368bb592aba6ebb18d9ff254  pkgconf-2.0.1.tar.xz
22b287bcd758831cbaf3356cd3054fe7  procps-ng-4.0.3.tar.xz
ed3206da1184ce9e82d607dc56c52633  psmisc-23.6.tar.xz
fb7f7eae520285788449d569e45b6718  Python-3.11.4.tar.xz
cdce7b1189bcf52947f3b434ab04d7e2  python-3.11.4-docs-html.tar.bz2
4aa1b31be779e6b84f9a96cb66bc50f6  readline-8.2.tar.gz
6aac9b2dbafcd5b7a67a8a9bcb8036c3  sed-4.9.tar.xz
b1ab01b5462ddcf43588374d57bec123  shadow-4.13.tar.xz
c70599ab0d037fde724f7210c2c8d7f8  sysklogd-1.5.1.tar.gz
0d266e5361dc72097b6c18cfde1c0001  systemd-254.tar.gz
fc32faeac581e1890ca27fcea3858410  systemd-man-pages-254.tar.xz
190398c660af29c97d892126d2a95e28  sysvinit-3.07.tar.xz
a2d8042658cfd8ea939e6d911eaf4152  tar-1.35.tar.xz
0e4358aade2f5db8a8b6f2f6d9481ec2  tcl8.6.13-src.tar.gz
4452f2f6d557f5598cca17b786d6eb68  tcl8.6.13-html.tar.gz
37bf94fd255729a14d4ea3dda119f81a  texinfo-7.0.3.tar.xz
5aa672bf129b44dd915f8232de38e49a  tzdata2023c.tar.gz
acd4360d8a5c3ef320b9db88d275dae6  udev-lfs-20230818.tar.xz
c542cd7c0726254e4b3006a9b428201a  util-linux-2.39.1.tar.xz
65e6b09ef0628a2d8eba79f1d1d5a564  vim-9.0.1677.tar.gz
181cb3f4d8ed340c904a0e1c416d341d  wheel-0.41.1.tar.gz
80bb18a8e6240fcf7ec2f7b57601c170  XML-Parser-2.46.tar.gz
d83d6f64a64f88759e312b8a38c3add6  xz-5.4.4.tar.xz
7d9fc1d78ae2fa3e84fe98b77d006c63  zlib-1.2.13.tar.xz
63251602329a106220e0a5ad26ba656f  zstd-1.5.5.tar.gz
6a5ac7e89b791aae556de0f745916f7f  bzip2-1.0.8-install_docs-1.patch
3c6340b3ddd62f4acdf8d3caa6fad6b0  coreutils-9.3-i18n-1.patch
2c3552bded42a83ad6a7087c5fbf3857  glibc-2.38-memalign_fix-1.patch
9a5997c3452909b1769918c759eff8a2  glibc-2.38-fhs-1.patch
da388905710bb4cbfbc7bd7346ff9174  grub-2.06-upstream_fixes-1.patch
f75cca16a38da6caa7d52151f7136895  kbd-2.6.1-backspace-1.patch
dd1764b84cfca6b677f44978218a75da  readline-8.2-upstream_fix-1.patch
17ffccbb8e18c39e8cedc32046f3a475  sysvinit-3.07-consolidated-1.patch
EOF

pushd $LFS/sources
  md5sum -c md5sums
popd


###################################
##### Packages needed in BLFS #####
###################################
cat > wget-list-sysv << "EOF"
https://anduin.linuxfromscratch.org/BLFS/blfs-bootscripts/blfs-bootscripts-20230824.tar.xz
https://www.sudo.ws/dist/sudo-1.9.14p3.tar.gz
https://mandoc.bsd.lv/snapshots/mandoc-1.14.6.tar.gz
https://github.com/rhboot/efivar/releases/download/38/efivar-38.tar.bz2
https://www.linuxfromscratch.org/patches/blfs/12.0/efivar-38-i686-1.patch
http://ftp.rpm.org/popt/releases/popt-1.x/popt-1.19.tar.gz
https://github.com/rhboot/efibootmgr/archive/18/efibootmgr-18.tar.gz
https://downloads.sourceforge.net/libpng/libpng-1.6.40.tar.xz
https://downloads.sourceforge.net/sourceforge/libpng-apng/libpng-1.6.39-apng.patch.gz
https://ftp.gnu.org/gnu/which/which-2.21.tar.gz
https://downloads.sourceforge.net/freetype/freetype-2.13.1.tar.xz
https://downloads.sourceforge.net/freetype/freetype-doc-2.13.1.tar.xz
https://github.com/unicode-org/icu/releases/download/release-73-2/icu4c-73_2-src.tgz
https://sourceware.org/pub/valgrind/valgrind-3.21.0.tar.bz2
https://download.gnome.org/sources/libxml2/2.10/libxml2-2.10.4.tar.xz
https://www.w3.org/XML/Test/xmlts20130923.tar.gz
https://sourceware.org/ftp/docbook-tools/new-trials/SOURCES/sgml-common-0.6.3.tgz
https://www.linuxfromscratch.org/patches/blfs/12.0/sgml-common-0.6.3-manpage-1.patch
https://downloads.sourceforge.net/infozip/unzip60.tar.gz
https://www.linuxfromscratch.org/patches/blfs/12.0/unzip-6.0-consolidated_fixes-1.patch
https://www.docbook.org/xml/4.5/docbook-xml-4.5.zip
https://github.com/docbook/xslt10-stylesheets/releases/download/release/1.79.2/docbook-xsl-nons-1.79.2.tar.bz2
https://www.linuxfromscratch.org/patches/blfs/12.0/docbook-xsl-nons-1.79.2-stack_fix-1.patch
https://github.com/docbook/xslt10-stylesheets/releases/download/release/1.79.2/docbook-xsl-doc-1.79.2.tar.bz2
https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.38.tar.xz
https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/pcre2-10.42.tar.bz2
https://download.gnome.org/sources/glib/2.76/glib-2.76.4.tar.xz
https://www.linuxfromscratch.org/patches/blfs/12.0/glib-skip_warnings-1.patch
https://www.freedesktop.org/software/desktop-file-utils/releases/desktop-file-utils-0.26.tar.xz
https://www.linuxfromscratch.org/patches/blfs/12.0/desktop-file-utils-0.26-update_standard-1.patch
https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/2.2/shared-mime-info-2.2.tar.gz
https://anduin.linuxfromscratch.org/BLFS/xdgmime/xdgmime.tar.xz
https://download.gnome.org/sources/gobject-introspection/1.76/gobject-introspection-1.76.1.tar.xz
https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.19.0.tar.gz
https://github.com/p11-glue/p11-kit/releases/download/0.25.0/p11-kit-0.25.0.tar.xz
https://github.com/lfs-book/make-ca/releases/download/v1.12/make-ca-1.12.tar.xz
https://curl.se/download/curl-8.2.1.tar.xz
https://github.com/libarchive/libarchive/releases/download/v3.7.1/libarchive-3.7.1.tar.xz
https://dist.libuv.org/dist/v1.46.0/libuv-v1.46.0.tar.gz
https://github.com/nghttp2/nghttp2/releases/download/v1.55.1/nghttp2-1.55.1.tar.xz
https://cmake.org/files/v3.27/cmake-3.27.2.tar.gz
https://github.com/silnrsi/graphite/releases/download/1.3.14/graphite2-1.3.14.tgz
https://github.com/harfbuzz/harfbuzz/releases/download/8.1.1/harfbuzz-8.1.1.tar.xz
https://unifoundry.com/pub/unifont/unifont-15.0.06/font-builds/unifont-15.0.06.pcf.gz
https://github.com/NetworkConfiguration/dhcpcd/releases/download/v10.0.2/dhcpcd-10.0.2.tar.xz
https://www.kernel.org/pub/linux/utils/net/bridge-utils/bridge-utils-1.7.1.tar.xz
https://ftp.gnu.org/gnu/wget/wget-1.21.4.tar.gz
https://github.com/thom311/libnl/releases/download/libnl3_7_0/libnl-3.7.0.tar.gz
https://github.com/thom311/libnl/releases/download/libnl3_7_0/libnl-doc-3.7.0.tar.gz
https://www.kernel.org/pub/software/network/iw/iw-5.19.tar.xz
https://hewlettpackard.github.io/wireless-tools/wireless_tools.29.tar.gz
https://www.linuxfromscratch.org/patches/blfs/12.0/wireless_tools-29-fix_iwlist_scanning-1.patch
https://w1.fi/releases/wpa_supplicant-2.10.tar.gz
https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.47.tar.bz2
https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.6.tar.bz2
https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.10.2.tar.bz2
https://www.gnupg.org/ftp/gcrypt/libksba/libksba-1.6.4.tar.bz2
https://www.gnupg.org/ftp/gcrypt/npth/npth-1.6.tar.bz2
https://anduin.linuxfromscratch.org/BLFS/bdb/db-5.3.28.tar.gz
https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.28/cyrus-sasl-2.1.28.tar.gz
https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.6.6.tgz
https://www.linuxfromscratch.org/patches/blfs/12.0/openldap-2.6.6-consolidated-1.patch
https://ftp.gnu.org/gnu/nettle/nettle-3.9.1.tar.gz
https://ftp.gnu.org/gnu/libunistring/libunistring-1.1.tar.xz
https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.1.tar.xz
https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-1.2.1.tar.bz2
https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-2.4.3.tar.bz2
https://www.linuxfromscratch.org/patches/blfs/12.0/gnupg-2.4.3-emacs-1.patch
https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.4p1.tar.gz
https://www.kernel.org/pub/software/scm/git/git-2.41.0.tar.xz
https://www.kernel.org/pub/software/scm/git/git-manpages-2.41.0.tar.xz
https://www.kernel.org/pub/software/scm/git/git-htmldocs-2.41.0.tar.xz
https://ftp.gnu.org/gnu/cpio/cpio-2.14.tar.bz2
https://invisible-mirror.net/archives/lynx/tarballs/lynx2.8.9rel.1.tar.bz2
https://www.linuxfromscratch.org/patches/blfs/12.0/lynx-2.8.9rel.1-security_fix-1.patch
https://mj.ucw.cz/download/linux/pci/pciutils-3.10.0.tar.gz
https://github.com/dosfstools/dosfstools/releases/download/v4.2/dosfstools-4.2.tar.gz
EOF

wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources

cat > $LFS/sources/md5sums << "EOF"
4cc21cf7c9a89290b230954aed0d1e11  sudo-1.9.14p3.tar.gz
f0adf24e8fdef5f3e332191f653e422a  mandoc-1.14.6.tar.gz
243fdbc48440212695cb9c6e6fd0f44f  efivar-38.tar.bz2
eaa2135fddb6eb03f2c87ee1823e5a78  popt-1.19.tar.gz
e170147da25e1d5f72721ffc46fe4e06  efibootmgr-18.tar.gz
6c7fe9dbb80c89c3579bedad9722e559  libpng-1.6.40.tar.xz
cd63b667723d6cc75e95eca3224f33f7  libpng-1.6.39-apng.patch.gz
097ff1a324ae02e0a3b0369f07a7544a  which-2.21.tar.gz
e4c3f0d8453a2a7993ae784912d6f19a  freetype-2.13.1.tar.xz
9eaaf193b0493297d92cd435cd850598  freetype-doc-2.13.1.tar.xz
b8a4b8cf77f2e2f6e1341eac0aab2fc4  icu4c-73_2-src.tgz
b8b89b327732c12191306c3d31cfd4b1  valgrind-3.21.0.tar.bz2
76808c467a58c31e2dbd511e71d5fd13  libxml2-2.10.4.tar.xz
103c9828f24820df86e55e7862e28974  sgml-common-0.6.3.tgz
62b490407489521db863b523a7f86375  unzip60.tar.gz
03083e288e87a7e829e437358da7ef9e  docbook-xml-4.5.zip
2666d1488d6ced1551d15f31d7ed8c38  docbook-xsl-nons-1.79.2.tar.bz2
62375ca864fc198cb2b17d98209d0b8c  docbook-xsl-doc-1.79.2.tar.bz2
7d6e43db810177ddf9818ef394027019  libxslt-1.1.38.tar.xz
a8e9ab2935d428a4807461f183034abe  pcre2-10.42.tar.bz2
b0df5864ec08248e79c13f71a717aa03  glib-2.76.4.tar.xz
29739e005f5887cf41639b8450f3c23f  desktop-file-utils-0.26.tar.xz
06cb9e92e4211dc53fd52b7bfd586c78  shared-mime-info-2.2.tar.gz
5cb554fdd139db79f9b1be13892fddac  gobject-introspection-1.76.1.tar.xz
f701ab57eb8e7d9c105b2cd5d809b29a  libtasn1-4.19.0.tar.gz
9fcb1ec80b5d083dd9b34122fa7c3c23  p11-kit-0.25.0.tar.xz
67e0b911e73a859fc326171c5153d455  make-ca-1.12.tar.xz
556576a795bdd2c7d10de6886480065f  curl-8.2.1.tar.xz
11a217b523dcdd178490bdb1f83353f3  libarchive-3.7.1.tar.xz
fa56dafe664d21f9568adebc428d2d64  libuv-v1.46.0.tar.gz
5af6a7ee55dc96661aa8649636b68763  nghttp2-1.55.1.tar.xz
07786cd23c3d0aa9c2fef69efb13662b  cmake-3.27.2.tar.gz
1bccb985a7da01092bfb53bb5041e836  graphite2-1.3.14.tgz
f0040d0fc02cf94cac9f46a94c44c6de  harfbuzz-8.1.1.tar.xz
94ff8cb4d5674cd2f38b00cede5e06d5  unifont-15.0.06.pcf.gz
1f266e2c32567bc778ea22c599fb06d9  dhcpcd-10.0.2.tar.xz
3e1fee4dc22cac5457c2f6ffb990a518  bridge-utils-1.7.1.tar.xz
e7f7ca2f215b711f76584756ebd3c853  wget-1.21.4.tar.gz
b381405afd14e466e35d29a112480333  libnl-3.7.0.tar.gz
15f55a421a16ff4084c4a1af085c19b8  libnl-doc-3.7.0.tar.gz
fd17ca2dd5f160a5d9e5fd3f8a69f416  iw-5.19.tar.xz
e06c222e186f7cc013fd272d023710cb  wireless_tools.29.tar.gz
d26797fcb002898d4ee989179346e1cc  wpa_supplicant-2.10.tar.gz
58e054ca192a77226c4822bbee1b7fdb  libgpg-error-1.47.tar.bz2
9c22e76168675ec996b9d620ffbb7b27  libassuan-2.5.6.tar.bz2
663abb395452750522d6797967e2f442  libgcrypt-1.10.2.tar.bz2
17a0b93de57cd91c7e3264b107723092  libksba-1.6.4.tar.bz2
375d1a15ad969f32d25f1a7630929854  npth-1.6.tar.bz2
b99454564d5b4479750567031d66fe24  db-5.3.28.tar.gz
6f228a692516f5318a64505b46966cfa  cyrus-sasl-2.1.28.tar.gz
5259e75484be71563e3f5c33d64a274d  openldap-2.6.6.tgz
29fcd2dec6bf5b48e5e3ffb3cbc4779e  nettle-3.9.1.tar.gz
0dfba19989ae06b8e7a49a7cd18472a1  libunistring-1.1.tar.xz
31a4b85586522c527b044597e86870a4  gnutls-3.8.1.tar.xz
be9b0d4bb493a139d2ec20e9b6872d37  pinentry-1.2.1.tar.bz2
e21ab42c629af80f19f813eeb61aa939  gnupg-2.4.3.tar.bz2
4bbd56a7ba51b0cd61debe8f9e77f8bb  openssh-9.4p1.tar.gz
c1f58a12b891ad73927b8e4a3aa29c7b  git-2.41.0.tar.xz
b153e1843561841d37190e48b891188d  cpio-2.14.tar.bz2
44316f1b8a857b59099927edc26bef79  lynx2.8.9rel.1.tar.bz2
ca53b87d2a94cdbbba6e09aca90924bd  pciutils-3.10.0.tar.gz
49c8e457327dc61efab5b115a27b087a  dosfstools-4.2.tar.gz
EOF

pushd $LFS/sources
  md5sum -c md5sums
popd


chown root:root $LFS/sources/*


# 4.2
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
mkdir -pv $LFS/tools


# 4.3
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
# passwd lfs
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
# su - lfs



# 4.4 to 6.18
cp ./part3.sh /home/lfs/
chown lfs /home/lfs/part3.sh
su lfs -c 'exec env -i HOME=$HOME TERM=$TERM PS1="\u:\w\$ " /bin/bash ~/part3.sh'



# 7.2
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac


# 7.3
mkdir -pv $LFS/{dev,proc,sys,run}
mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
else
  mount -t tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi



# 7.4 to 9.2 with additional packages
cp ./part4.sh $LFS/sources/
cp ./part5.sh $LFS/sources/
cp ./part6.sh $LFS/sources/
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash /sources/part4.sh



userdel -r lfs



# 11.3
# umount -v $LFS/dev/pts
# mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
# umount -v $LFS/dev
# umount -v $LFS/run
# umount -v $LFS/proc
# umount -v $LFS/sys
