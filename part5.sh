#!/bin/bash
set -e

## If a package is needed, all packages which are required or recommended as dependencies by BLFS are installed.
## A -> B means that A is a dependency of B
## The installation sequence follows the dependency description.
## For the last program in each line, unless it is explicitly installed, it is only used to indicate dependency and not ready for installation yet.


# Install GRUB
#                                                                               mandoc -> efivar -> efibootmgr
#                                                                                           Popt -> efibootmgr -> GRUB
#                                                            libpng, Which -> FreeType -> HarfBuzz
#          ICU , Valgrind-> libxml2 -> libxslt
# sgml-common, UnZip -> docbook-xml -> libxslt
#                  docbook-xsl-nons -> libxslt -> GLib
#                                        PCRE2 -> GLib (install)
#         desktop-file-utils, shared-mime-info -> GLib (test) -> gobject-introspection -> HarfBuzz
#                         libtasn1 -> p11-kit -> make-ca -> cURL -> CMake
#                                     libarchive, libuv, nghttp2 -> CMake -> Graphite2 -> HarfBuzz -> FreeType -> GRUB (install)

# Install networking programs
# dhcpcd, bridge-utils, Wget, libnl, iw, Wireless Tools, wpa_supplicant

# Install git
# libgpg-error -> libassuan, libgcrypt, libksba, npth -> GnuPG
#               Berkeley DB -> Cyrus SASL -> OpenLDAP -> GnuPG
#                      Nettle, libunistring -> GnuTLS -> GnuPG
#                                            pinentry -> GnuPG -> Git
#                                                      OpenSSH -> Git (install)

# Install firmware tools
# cpio, Lynx, pciutils

# Install file system
# dosfstools



cd /sources
export MAKEFLAGS="-j`nproc`"

# Install GRUB

tar -xf mandoc-1.14.6.tar.gz
cd mandoc-1.14.6
./configure &&
make mandoc
make regress
sudo install -vm755 mandoc   /usr/bin &&
sudo install -vm644 mandoc.1 /usr/share/man/man1
cd ..
rm -rf mandoc-1.14.6


tar -xf efivar-38.tar.bz2
cd efivar-38
sed '/prep :/a\\ttouch prep' -i src/Makefile
[ $(getconf LONG_BIT) = 64 ] || patch -Np1 -i ../efivar-38-i686-1.patch
make ERRORS=
sudo make install LIBDIR=/usr/lib
cd ..
rm -rf efivar-38


tar -xf popt-1.19.tar.gz
cd popt-1.19
./configure --prefix=/usr --disable-static &&
make
make check
sudo make install
cd ..
rm -rf popt-1.19


tar -xf efibootmgr-18.tar.gz
cd efibootmgr-18
make EFIDIR=LFS EFI_LOADER=grubx64.efi
sudo make install EFIDIR=LFS
cd ..
rm -rf efibootmgr-18


tar -xf libpng-1.6.40.tar.xz
cd libpng-1.6.40
gzip -cd ../libpng-1.6.39-apng.patch.gz | patch -p1
./configure --prefix=/usr --disable-static &&
make
make check
sudo make install &&
sudo mkdir -v /usr/share/doc/libpng-1.6.40 &&
sudo cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.40
cd ..
rm -rf libpng-1.6.40


tar -xf which-2.21.tar.gz
cd which-2.21
./configure --prefix=/usr &&
make
sudo make install
cd ..
rm -rf which-2.21


tar -xf freetype-2.13.1.tar.xz
cd freetype-2.13.1
tar -xf ../freetype-doc-2.13.1.tar.xz --strip-components=2 -C docs
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h  &&

./configure --prefix=/usr --enable-freetype-config --disable-static &&
make
sudo make install
sudo cp -v -R docs -T /usr/share/doc/freetype-2.13.1 &&
sudo rm -v /usr/share/doc/freetype-2.13.1/freetype-config.1
cd ..
rm -rf freetype-2.13.1


tar -xf icu4c-73_2-src.tgz
cd icu
cd source &&
./configure --prefix=/usr &&
make
## One test named TestHebrewCalendarInTemporalLeapYear may fail
# make check
sudo make install
cd ../..
rm -rf icu


tar -xf valgrind-3.21.0.tar.bz2
cd valgrind-3.21.0
sed -i 's|/doc/valgrind||' docs/Makefile.in &&

./configure --prefix=/usr \
            --datadir=/usr/share/doc/valgrind-3.21.0 \
            --enable-lto=yes &&
make
sed -e 's@prereq:.*@prereq: false@' \
    -i {helgrind,drd}/tests/pth_cond_destroy_busy.vgtest
## The tests may hang forever when GDB is not installed
# make regtest
sudo make install
cd ..
rm -rf valgrind-3.21.0


tar -xf libxml2-2.10.4.tar.xz
cd libxml2-2.10.4
./configure --prefix=/usr           \
            --sysconfdir=/etc       \
            --disable-static        \
            --with-history          \
            PYTHON=/usr/bin/python3 \
            --with-icu              \
            --docdir=/usr/share/doc/libxml2-2.10.4 &&
make
tar xf ../xmlts20130923.tar.gz
make check
make check-valgrind
sudo make install
cd ..
rm -rf libxml2-2.10.4
sudo rm -vf /usr/lib/libxml2.la &&
sudo sed '/libs=/s/xml2.*/xml2"/' -i /usr/bin/xml2-config


tar -xf sgml-common-0.6.3.tgz
cd sgml-common-0.6.3
patch -Np1 -i ../sgml-common-0.6.3-manpage-1.patch &&
autoreconf -f -i
./configure --prefix=/usr --sysconfdir=/etc &&
make
sudo make docdir=/usr/share/doc install &&
sudo install-catalog --add /etc/sgml/sgml-ent.cat \
    /usr/share/sgml/sgml-iso-entities-8879.1986/catalog &&
sudo install-catalog --add /etc/sgml/sgml-docbook.cat \
    /etc/sgml/sgml-ent.cat
cd ..
rm -rf sgml-common-0.6.3


tar -xf unzip60.tar.gz
cd unzip60
patch -Np1 -i ../unzip-6.0-consolidated_fixes-1.patch
make -f unix/Makefile generic
sudo make prefix=/usr MANDIR=/usr/share/man/man1 \
 -f unix/Makefile install
cd ..
rm -rf unzip60


mkdir docbook-xml-4.5
unzip docbook-xml-4.5.zip -d docbook-xml-4.5
cd docbook-xml-4.5
cat > install.sh << "EOF"
#!/bin/bash
set -e

install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5 &&
install -v -d -m755 /etc/xml &&
cp -v -af --no-preserve=ownership docbook.cat *.dtd ent/ *.mod \
    /usr/share/xml/docbook/xml-dtd-4.5

if [ ! -e /etc/xml/docbook ]; then
    xmlcatalog --noout --create /etc/xml/docbook
fi &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V4.5//EN" \
    "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook

if [ ! -e /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog

for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
  xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
    /etc/xml/docbook
  xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
  xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
done
EOF
sudo /bin/bash install.sh
cd ..
rm -rf docbook-xml-4.5


tar -xf docbook-xsl-nons-1.79.2.tar.bz2
cd docbook-xsl-nons-1.79.2
patch -Np1 -i ../docbook-xsl-nons-1.79.2-stack_fix-1.patch
tar -xf ../docbook-xsl-doc-1.79.2.tar.bz2 --strip-components=1
cat > install.sh << "EOF"
#!/bin/bash
set -e

install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&

cp -v -R VERSION assembly common eclipse epub epub3 extensions fo        \
         highlighting html htmlhelp images javahelp lib manpages params  \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5                                          \
    /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&

ln -s VERSION /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/VERSION.xsl &&

install -v -m644 -D README \
                    /usr/share/doc/docbook-xsl-nons-1.79.2/README.txt &&
install -v -m644    RELEASE-NOTES* NEWS* \
                    /usr/share/doc/docbook-xsl-nons-1.79.2

cp -v -R doc/* /usr/share/doc/docbook-xsl-nons-1.79.2

if [ ! -d /etc/xml ]; then install -v -m755 -d /etc/xml; fi &&
if [ ! -f /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&

xmlcatalog --noout --add "rewriteSystem" \
           "https://cdn.docbook.org/release/xsl-nons/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "https://cdn.docbook.org/release/xsl-nons/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "https://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "https://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog
EOF
sudo bash install.sh
cd ..
rm -rf docbook-xsl-nons-1.79.2


tar -xf libxslt-1.1.38.tar.xz
cd libxslt-1.1.38
./configure --prefix=/usr                          \
            --disable-static                       \
            --docdir=/usr/share/doc/libxslt-1.1.38 \
            PYTHON=/usr/bin/python3 &&
make
make check
sudo make install
cd ..
rm -rf libxslt-1.1.38


tar -xf pcre2-10.42.tar.bz2
cd pcre2-10.42
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/pcre2-10.42 \
            --enable-unicode                    \
            --enable-jit                        \
            --enable-pcre2-16                   \
            --enable-pcre2-32                   \
            --enable-pcre2grep-libz             \
            --enable-pcre2grep-libbz2           \
            --enable-pcre2test-libreadline      \
            --disable-static                    &&
make
make check
sudo make install
cd ..
rm -rf pcre2-10.42


tar -xf glib-2.76.4.tar.xz
cd glib-2.76.4
patch -Np1 -i ../glib-skip_warnings-1.patch
mkdir build &&
cd    build &&
meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -Dman=true          &&
ninja
sudo ninja install &&
sudo mkdir -p /usr/share/doc/glib-2.76.4 &&
sudo cp -r ../docs/reference/{gio,glib,gobject} /usr/share/doc/glib-2.76.4
## Will be continued
cd ../..


tar -xf desktop-file-utils-0.26.tar.xz
cd desktop-file-utils-0.26
rm -fv /usr/bin/desktop-file-edit
patch -Np1 -i ../desktop-file-utils-0.26-update_standard-1.patch
mkdir build &&
cd    build &&
meson setup --prefix=/usr --buildtype=release .. &&
ninja
sudo ninja install
cd ../..
rm -rf desktop-file-utils-0.26


tar -xf shared-mime-info-2.2.tar.gz
cd shared-mime-info-2.2
tar -xf ../xdgmime.tar.xz &&
make -C xdgmime
mkdir build &&
cd    build &&
meson setup --prefix=/usr --buildtype=release -Dupdate-mimedb=true .. &&
ninja
ninja test
sudo ninja install
cd ../..
rm -rf shared-mime-info-2.2


cd glib-2.76.4/build
## Continued
## One test is known to fail
LC_ALL=C ninja test > /sources/glib.check || true
cd ../..
rm -rf glib-2.76.4


tar -xf gobject-introspection-1.76.1.tar.xz
cd gobject-introspection-1.76.1
mkdir build &&
cd    build &&
meson setup --prefix=/usr --buildtype=release .. &&
ninja
ninja test
sudo ninja install
cd ../..
rm -rf gobject-introspection-1.76.1


tar -xf libtasn1-4.19.0.tar.gz
cd libtasn1-4.19.0
./configure --prefix=/usr --disable-static &&
make
make check
sudo make install
sudo make -C doc/reference install-data-local
cd ..
rm -rf libtasn1-4.19.0


tar -xf p11-kit-0.25.0.tar.xz
cd p11-kit-0.25.0
sed 's/if (gi/& \&\& gi != C_GetInterface/' \
    -i p11-kit/modules.c
sed '20,$ d' -i trust/trust-extract-compat &&
cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF
mkdir p11-build &&
cd    p11-build &&
meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -Dtrust_paths=/etc/pki/anchors &&
ninja
ninja test
sudo ninja install &&
sudo ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates
sudo ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
cd ../..
rm -rf p11-kit-0.25.0


tar -xf make-ca-1.12.tar.xz
cd make-ca-1.12
## Fix the problem in mozilla-ca-root.pem
rm -rf mozilla-ca-root.pem
cat > mozilla-ca-root.pem << "EOF"
-----BEGIN CERTIFICATE-----
MIIDjjCCAnagAwIBAgIQAzrx5qcRqaC7KGSxHQn65TANBgkqhkiG9w0BAQsFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBH
MjAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGExCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEcyMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzfNNNx7a8myaJCtSnX/RrohCgiN9RlUyfuI
2/Ou8jqJkTx65qsGGmvPrC3oXgkkRLpimn7Wo6h+4FR1IAWsULecYxpsMNzaHxmx
1x7e/dfgy5SDN67sH0NO3Xss0r0upS/kqbitOtSZpLYl6ZtrAGCSYP9PIUkY92eQ
q2EGnI/yuum06ZIya7XzV+hdG82MHauVBJVJ8zUtluNJbd134/tJS7SsVQepj5Wz
tCO7TG1F8PapspUwtP1MVYwnSlcUfIKdzXOS0xZKBgyMUNGPHgm+F6HmIcr9g+UQ
vIOlCsRnKPZzFBQ9RnbDhxSJITRNrw9FDKZJobq7nMWxM4MphQIDAQABo0IwQDAP
BgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUTiJUIBiV
5uNu5g/6+rkS7QYXjzkwDQYJKoZIhvcNAQELBQADggEBAGBnKJRvDkhj6zHd6mcY
1Yl9PMWLSn/pvtsrF9+wX3N3KjITOYFnQoQj8kVnNeyIv/iPsGEMNKSuIEyExtv4
NeF22d+mQrvHRAiGfzZ0JFrabA0UWTW98kndth/Jsw1HKj2ZL7tcu7XUIOGZX1NG
Fdtom/DzMNU+MeKNhJ7jitralj41E6Vf8PlwUHBHQRFXGU7Aj64GxJUTFy8bJZ91
8rGOmaFvE7FBcf6IKshPECBV1/MUReXgRPTqh5Uykw7+U0b6LJ3/iyK5S9kJRaTe
pLiaWN0bfVKfjllDiIGknibVb63dDcY3fe0Dkhvld1927jyNxF1WW6LZZm6zNTfl
MrY=
-----END CERTIFICATE-----
EOF
sudo make install &&
sudo install -vdm755 /etc/ssl/local
sudo /usr/sbin/make-ca -g
cd ..
rm -rf make-ca-1.12


tar -xf curl-8.2.1.tar.xz
cd curl-8.2.1
./configure --prefix=/usr                           \
            --disable-static                        \
            --with-openssl                          \
            --enable-threaded-resolver              \
            --with-ca-path=/etc/ssl/certs &&
make
make test
sudo make install &&
sudo rm -rf docs/examples/.deps &&
sudo find docs \( -name Makefile\* -o  \
             -name \*.1       -o  \
             -name \*.3       -o  \
             -name CMakeLists.txt \) -delete &&
sudo cp -v -R docs -T /usr/share/doc/curl-8.2.1
cd ..
rm -rf curl-8.2.1


tar -xf libarchive-3.7.1.tar.xz
cd libarchive-3.7.1
./configure --prefix=/usr --disable-static &&
make
LC_ALL=C make check
sudo make install
cd ..
rm -rf libarchive-3.7.1


tar -xf libuv-v1.46.0.tar.gz
cd libuv-v1.46.0
sh autogen.sh &&
./configure --prefix=/usr --disable-static &&
make
## Two tests named tcp_bind6_error_addrinuse and tcp_bind_error_addrinuse_listen may fail
# make check
sudo make install
cd ..
rm -rf libuv-v1.46.0


tar -xf nghttp2-1.55.1.tar.xz
cd nghttp2-1.55.1
./configure --prefix=/usr     \
            --disable-static  \
            --enable-lib-only \
            --docdir=/usr/share/doc/nghttp2-1.55.1 &&
make
sudo make install
cd ..
rm -rf nghttp2-1.55.1


tar -xf cmake-3.27.2.tar.gz
cd cmake-3.27.2
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake &&
./bootstrap --prefix=/usr        \
            --system-libs        \
            --mandir=/share/man  \
            --no-system-jsoncpp  \
            --no-system-cppdap   \
            --no-system-librhash \
            --docdir=/share/doc/cmake-3.27.2 &&
make
LC_ALL=en_US.UTF-8 bin/ctest -j`nproc` -O cmake-3.27.2-test.log
sudo make install
cd ..
rm -rf cmake-3.27.2


tar -xf graphite2-1.3.14.tgz
cd graphite2-1.3.14
sed -i '/cmptest/d' tests/CMakeLists.txt
mkdir build &&
cd    build &&
cmake -DCMAKE_INSTALL_PREFIX=/usr .. &&
make
## One test is known to fail
# make test
sudo make install
cd ../..
rm -rf graphite2-1.3.14


tar -xf harfbuzz-8.1.1.tar.xz
cd harfbuzz-8.1.1
mkdir build &&
cd    build &&
meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -Dgraphite2=enabled &&
ninja
ninja test
sudo ninja install
cd ../..
rm -rf harfbuzz-8.1.1


tar -xf freetype-2.13.1.tar.xz
cd freetype-2.13.1
tar -xf ../freetype-doc-2.13.1.tar.xz --strip-components=2 -C docs
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&
sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h  &&
./configure --prefix=/usr --enable-freetype-config --disable-static &&
make
sudo make install
sudo cp -v -R docs -T /usr/share/doc/freetype-2.13.1 &&
sudo rm -v /usr/share/doc/freetype-2.13.1/freetype-config.1
cd ..
rm -rf freetype-2.13.1


tar -xf grub-2.06.tar.xz
cd grub-2.06
sudo mkdir -pv /usr/share/fonts/unifont &&
gunzip -c ../unifont-15.0.06.pcf.gz | sudo tee /usr/share/fonts/unifont/unifont.pcf > /dev/null
unset {C,CPP,CXX,LD}FLAGS
patch -Np1 -i ../grub-2.06-upstream_fixes-1.patch
case $(uname -m) in i?86 )
    tar xf ../gcc-13.2.0.tar.xz
    mkdir gcc-13.2.0/build
    pushd gcc-13.2.0/build
        ../configure --prefix=$PWD/../../x86_64-gcc \
                     --target=x86_64-linux-gnu      \
                     --with-system-zlib             \
                     --enable-languages=c,c++       \
                     --with-ld=/usr/bin/ld
        make all-gcc
        make install-gcc
    popd
    export TARGET_CC=$PWD/x86_64-gcc/bin/x86_64-linux-gnu-gcc
esac
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --disable-efiemu     \
            --enable-grub-mkfont \
            --with-platform=efi  \
            --target=x86_64      \
            --disable-werror     &&
unset TARGET_CC &&
make
sudo make install &&
sudo mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
cd ..
rm -rf grub-2.06

# GRUB installed


# Install networking programs

tar -xf dhcpcd-10.0.2.tar.xz
cd dhcpcd-10.0.2
./configure --prefix=/usr                \
            --sysconfdir=/etc            \
            --libexecdir=/usr/lib/dhcpcd \
            --dbdir=/var/lib/dhcpcd      \
            --runstatedir=/run           \
            --disable-privsep         &&
make
make test
sudo make install
cd ..
rm -rf dhcpcd-10.0.2

tar -xf blfs-bootscripts-20230824.tar.xz
cd blfs-bootscripts-20230824
sudo make install-service-dhcpcd
cd ..
rm -rf blfs-bootscripts-20230824


## Kernel configuration
tar -xf bridge-utils-1.7.1.tar.xz
cd bridge-utils-1.7.1
autoconf                  &&
./configure --prefix=/usr &&
make
sudo make install
cd ..
rm -rf bridge-utils-1.7.1

tar -xf blfs-bootscripts-20230824.tar.xz
cd blfs-bootscripts-20230824
sudo make install-service-bridge
cd ..
rm -rf blfs-bootscripts-20230824


tar -xf wget-1.21.4.tar.gz
cd wget-1.21.4
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl &&
make
## Some tests may fail when Valgrind tests are enabled
# make check
sudo make install
cd ..
rm -rf wget-1.21.4


tar -xf libnl-3.7.0.tar.gz
cd libnl-3.7.0
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  &&
make
sudo make install
sudo mkdir -vp /usr/share/doc/libnl-3.7.0 &&
sudo tar -xf ../libnl-doc-3.7.0.tar.gz --strip-components=1 --no-same-owner \
    -C  /usr/share/doc/libnl-3.7.0
cd ..
rm -rf libnl-3.7.0


## Kernel configuration
tar -xf iw-5.19.tar.xz
cd iw-5.19
sed -i "/INSTALL.*gz/s/.gz//" Makefile &&
make
sudo make install
cd ..
rm -rf iw-5.19


## Kernel configuration
tar -xf wireless_tools.29.tar.gz
cd wireless_tools.29
patch -Np1 -i ../wireless_tools-29-fix_iwlist_scanning-1.patch
make
sudo make PREFIX=/usr INSTALL_MAN=/usr/share/man install
cd ..
rm -rf wireless_tools.29


tar -xf wpa_supplicant-2.10.tar.gz
cd wpa_supplicant-2.10
cat > wpa_supplicant/.config << "EOF"
CONFIG_BACKEND=file
CONFIG_CTRL_IFACE=y
CONFIG_DEBUG_FILE=y
CONFIG_DEBUG_SYSLOG=y
CONFIG_DEBUG_SYSLOG_FACILITY=LOG_DAEMON
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y
CONFIG_EAP_GTC=y
CONFIG_EAP_LEAP=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_OTP=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_IPV6=y
CONFIG_LIBNL32=y
CONFIG_PEERKEY=y
CONFIG_PKCS12=y
CONFIG_READLINE=y
CONFIG_SMARTCARD=y
CONFIG_WPS=y
CFLAGS += -I/usr/include/libnl3
EOF
cd wpa_supplicant &&
make BINDIR=/usr/sbin LIBDIR=/usr/lib
sudo install -v -m755 wpa_{cli,passphrase,supplicant} /usr/sbin/ &&
sudo install -v -m644 doc/docbook/wpa_supplicant.conf.5 /usr/share/man/man5/ &&
sudo install -v -m644 doc/docbook/wpa_{cli,passphrase,supplicant}.8 /usr/share/man/man8/
cd ../..
rm -rf wpa_supplicant-2.10

tar -xf blfs-bootscripts-20230824.tar.xz
cd blfs-bootscripts-20230824
sudo make install-service-wpa
cd ..
rm -rf blfs-bootscripts-20230824

# Networking programs installed

# Install git

tar -xf libgpg-error-1.47.tar.bz2
cd libgpg-error-1.47
./configure --prefix=/usr &&
make
make check
sudo make install &&
sudo install -v -m644 -D README /usr/share/doc/libgpg-error-1.47/README
cd ..
rm -rf libgpg-error-1.47


tar -xf libassuan-2.5.6.tar.bz2
cd libassuan-2.5.6
./configure --prefix=/usr &&
make                      &&
make -C doc html                                                       &&
makeinfo --html --no-split -o doc/assuan_nochunks.html doc/assuan.texi &&
makeinfo --plaintext       -o doc/assuan.txt           doc/assuan.texi
make check
sudo make install &&
sudo install -v -dm755   /usr/share/doc/libassuan-2.5.6/html &&
sudo install -v -m644 doc/assuan.html/* \
                    /usr/share/doc/libassuan-2.5.6/html &&
sudo install -v -m644 doc/assuan_nochunks.html \
                    /usr/share/doc/libassuan-2.5.6      &&
sudo install -v -m644 doc/assuan.{txt,texi} \
                    /usr/share/doc/libassuan-2.5.6
cd ..
rm -rf libassuan-2.5.6


tar -xf libgcrypt-1.10.2.tar.bz2
cd libgcrypt-1.10.2
./configure --prefix=/usr &&
make                      &&
make -C doc html                                                       &&
makeinfo --html --no-split -o doc/gcrypt_nochunks.html doc/gcrypt.texi &&
makeinfo --plaintext       -o doc/gcrypt.txt           doc/gcrypt.texi
make check
sudo make install &&
sudo install -v -dm755   /usr/share/doc/libgcrypt-1.10.2 &&
sudo install -v -m644    README doc/{README.apichanges,fips*,libgcrypt*} \
                    /usr/share/doc/libgcrypt-1.10.2 &&
sudo install -v -dm755   /usr/share/doc/libgcrypt-1.10.2/html &&
sudo install -v -m644 doc/gcrypt.html/* \
                    /usr/share/doc/libgcrypt-1.10.2/html &&
sudo install -v -m644 doc/gcrypt_nochunks.html \
                    /usr/share/doc/libgcrypt-1.10.2      &&
sudo install -v -m644 doc/gcrypt.{txt,texi} \
                    /usr/share/doc/libgcrypt-1.10.2
cd ..
rm -rf libgcrypt-1.10.2


tar -xf libksba-1.6.4.tar.bz2
cd libksba-1.6.4
./configure --prefix=/usr &&
make
make check
sudo make install
cd ..
rm -rf libksba-1.6.4


tar -xf npth-1.6.tar.bz2
cd npth-1.6
./configure --prefix=/usr &&
make
make check
sudo make install
cd ..
rm -rf npth-1.6


tar -xf db-5.3.28.tar.gz
cd db-5.3.28
sed -i 's/\(__atomic_compare_exchange\)/\1_db/' src/dbinc/atomic.h
cd build_unix                        &&
../dist/configure --prefix=/usr      \
                  --enable-compat185 \
                  --enable-dbm       \
                  --disable-static   \
                  --enable-cxx       &&
make
sudo make docdir=/usr/share/doc/db-5.3.28 install &&
sudo chown -v -R root:root                        \
      /usr/bin/db_*                          \
      /usr/include/db{,_185,_cxx}.h          \
      /usr/lib/libdb*.{so,la}                \
      /usr/share/doc/db-5.3.28
cd ../..
rm -rf db-5.3.28


tar -xf cyrus-sasl-2.1.28.tar.gz
cd cyrus-sasl-2.1.28
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --enable-auth-sasldb \
            --with-dbpath=/var/lib/sasl/sasldb2 \
            --with-sphinx-build=no              \
            --with-saslauthd=/var/run/saslauthd &&
make -j1
sudo make install &&
sudo install -v -dm755                          /usr/share/doc/cyrus-sasl-2.1.28/html &&
sudo install -v -m644  saslauthd/LDAP_SASLAUTHD /usr/share/doc/cyrus-sasl-2.1.28      &&
sudo install -v -m644  doc/legacy/*.html        /usr/share/doc/cyrus-sasl-2.1.28/html &&
sudo install -v -dm700 /var/lib/sasl
cd ..
rm -rf cyrus-sasl-2.1.28


tar -xf openldap-2.6.6.tgz
cd openldap-2.6.6
sudo groupadd -g 83 ldap &&
sudo useradd  -c "OpenLDAP Daemon Owner" \
         -d /var/lib/openldap -u 83 \
         -g ldap -s /bin/false ldap
patch -Np1 -i ../openldap-2.6.6-consolidated-1.patch &&
autoconf &&
./configure --prefix=/usr         \
            --sysconfdir=/etc     \
            --localstatedir=/var  \
            --libexecdir=/usr/lib \
            --disable-static      \
            --enable-versioning=yes \
            --disable-debug       \
            --with-tls=openssl    \
            --with-cyrus-sasl     \
            --without-systemd     \
            --enable-dynamic      \
            --enable-crypt        \
            --enable-spasswd      \
            --enable-slapd        \
            --enable-modules      \
            --enable-rlookups     \
            --enable-backends=mod \
            --disable-sql         \
            --disable-wt          \
            --enable-overlays=mod &&
make depend &&
make
## Some errors may happen due to timing problems
# make test
sudo make install &&
sudo  sed -e "s/\.la/.so/" -i /etc/openldap/slapd.{conf,ldif}{,.default} &&
sudo install -v -dm700 -o ldap -g ldap /var/lib/openldap     &&
sudo install -v -dm700 -o ldap -g ldap /etc/openldap/slapd.d &&
sudo chmod   -v    640     /etc/openldap/slapd.{conf,ldif}   &&
sudo chown   -v  root:ldap /etc/openldap/slapd.{conf,ldif}   &&
sudo install -v -dm755 /usr/share/doc/openldap-2.6.6 &&
sudo cp      -vfr      doc/{drafts,rfc,guide} \
                  /usr/share/doc/openldap-2.6.6
cd ..
rm -rf openldap-2.6.6


tar -xf nettle-3.9.1.tar.gz
cd nettle-3.9.1
./configure --prefix=/usr --disable-static &&
make
make check
sudo make install &&
sudo chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so &&
sudo install -v -m755 -d /usr/share/doc/nettle-3.9.1 &&
sudo install -v -m644 nettle.{html,pdf} /usr/share/doc/nettle-3.9.1
cd ..
rm -rf nettle-3.9.1


tar -xf libunistring-1.1.tar.xz
cd libunistring-1.1
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libunistring-1.1 &&
make
make check
sudo make install
cd ..
rm -rf libunistring-1.1


tar -xf gnutls-3.8.1.tar.xz
cd gnutls-3.8.1
./configure --prefix=/usr \
            --docdir=/usr/share/doc/gnutls-3.8.1 \
            --with-default-trust-store-pkcs11="pkcs11:" &&
make
make check
sudo make install
cd ..
rm -rf gnutls-3.8.1


tar -xf pinentry-1.2.1.tar.bz2
cd pinentry-1.2.1
./configure --prefix=/usr --enable-pinentry-tty &&
make
sudo make install
cd ..
rm -rf pinentry-1.2.1


tar -xf gnupg-2.4.3.tar.bz2
cd gnupg-2.4.3
patch -Np1 -i ../gnupg-2.4.3-emacs-1.patch
mkdir build &&
cd    build &&
../configure --prefix=/usr           \
             --localstatedir=/var    \
             --sysconfdir=/etc       \
             --enable-all-tests      \
             --docdir=/usr/share/doc/gnupg-2.4.3 &&
make &&
makeinfo --html --no-split -I doc -o doc/gnupg_nochunks.html ../doc/gnupg.texi &&
makeinfo --plaintext       -I doc -o doc/gnupg.txt           ../doc/gnupg.texi &&
make -C doc html
make check
sudo make install &&
sudo install -v -m755 -d /usr/share/doc/gnupg-2.4.3/html            &&
sudo install -v -m644    doc/gnupg_nochunks.html \
                    /usr/share/doc/gnupg-2.4.3/html/gnupg.html &&
sudo install -v -m644    ../doc/*.texi doc/gnupg.txt \
                    /usr/share/doc/gnupg-2.4.3 &&
sudo install -v -m644    doc/gnupg.html/* \
                    /usr/share/doc/gnupg-2.4.3/html
cd ../..
rm -rf gnupg-2.4.3


tar -xf openssh-9.4p1.tar.gz
cd openssh-9.4p1
sudo install -v -g sys -m700 -d /var/lib/sshd &&
sudo groupadd -g 50 sshd        &&
sudo useradd  -c 'sshd PrivSep' \
              -d /var/lib/sshd  \
              -g sshd           \
              -s /bin/false     \
              -u 50 sshd
./configure --prefix=/usr                            \
            --sysconfdir=/etc/ssh                    \
            --with-privsep-path=/var/lib/sshd        \
            --with-default-path=/usr/bin             \
            --with-superuser-path=/usr/sbin:/usr/bin \
            --with-pid-dir=/run                      &&
make
make -j1 tests
sudo make install &&
sudo install -v -m755    contrib/ssh-copy-id /usr/bin     &&
sudo install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
sudo install -v -m755 -d /usr/share/doc/openssh-9.4p1     &&
sudo install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-9.4p1
cd ..
rm -rf openssh-9.4p1


tar -xf git-2.41.0.tar.xz
cd git-2.41.0
./configure --prefix=/usr \
            --with-gitconfig=/etc/gitconfig \
            --with-python=python3           \
            --with-libpcre2 &&
make
make -k test
sudo make perllibdir=/usr/lib/perl5/5.38/site_perl install
sudo tar -xf ../git-manpages-2.41.0.tar.xz \
    -C /usr/share/man --no-same-owner --no-overwrite-dir
sudo mkdir -vp   /usr/share/doc/git-2.41.0 &&
sudo tar   -xf   ../git-htmldocs-2.41.0.tar.xz \
      -C    /usr/share/doc/git-2.41.0 --no-same-owner --no-overwrite-dir &&
sudo find        /usr/share/doc/git-2.41.0 -type d -exec chmod 755 {} \; &&
sudo find        /usr/share/doc/git-2.41.0 -type f -exec chmod 644 {} \;
sudo mkdir -vp /usr/share/doc/git-2.41.0/man-pages/{html,text}         &&
sudo mv        /usr/share/doc/git-2.41.0/{git*.txt,man-pages/text}     &&
sudo mv        /usr/share/doc/git-2.41.0/{git*.,index.,man-pages/}html &&
sudo mkdir -vp /usr/share/doc/git-2.41.0/technical/{html,text}         &&
sudo mv        /usr/share/doc/git-2.41.0/technical/{*.txt,text}        &&
sudo mv        /usr/share/doc/git-2.41.0/technical/{*.,}html           &&
sudo mkdir -vp /usr/share/doc/git-2.41.0/howto/{html,text}             &&
sudo mv        /usr/share/doc/git-2.41.0/howto/{*.txt,text}            &&
sudo mv        /usr/share/doc/git-2.41.0/howto/{*.,}html               &&
sudo sed -i '/^<a href=/s|howto/|&html/|' /usr/share/doc/git-2.41.0/howto-index.html &&
sudo sed -i '/^\* link:/s|howto/|&html/|' /usr/share/doc/git-2.41.0/howto-index.txt
cd ..
rm -rf git-2.41.0

# git installed


# Install firmware tools

tar -xf cpio-2.14.tar.bz2
cd cpio-2.14
./configure --prefix=/usr \
            --enable-mt   \
            --with-rmt=/usr/libexec/rmt &&
make &&
makeinfo --html            -o doc/html      doc/cpio.texi &&
makeinfo --html --no-split -o doc/cpio.html doc/cpio.texi &&
makeinfo --plaintext       -o doc/cpio.txt  doc/cpio.texi
make check
sudo make install &&
sudo install -v -m755 -d /usr/share/doc/cpio-2.14/html &&
sudo install -v -m644    doc/html/* \
                    /usr/share/doc/cpio-2.14/html &&
sudo install -v -m644    doc/cpio.{html,txt} \
                    /usr/share/doc/cpio-2.14
cd ..
rm -rf cpio-2.14


tar -xf lynx2.8.9rel.1.tar.bz2
cd lynx2.8.9rel.1
patch -p1 -i ../lynx-2.8.9rel.1-security_fix-1.patch
./configure --prefix=/usr           \
            --sysconfdir=/etc/lynx  \
            --datadir=/usr/share/doc/lynx-2.8.9rel.1 \
            --with-zlib             \
            --with-bzlib            \
            --with-ssl              \
            --with-screen=ncursesw  \
            --enable-locale-charset \
            --enable-ipv6           \
            --enable-nls &&
make
sudo make install-full &&
sudo chgrp -v -R root /usr/share/doc/lynx-2.8.9rel.1/lynx_doc
sudo sed -e '/#LOCALE/     a LOCALE_CHARSET:TRUE'     \
    -i /etc/lynx/lynx.cfg
sudo sed -e '/#DEFAULT_ED/ a DEFAULT_EDITOR:vi'       \
    -i /etc/lynx/lynx.cfg
sudo sed -e '/#PERSIST/    a PERSISTENT_COOKIES:TRUE' \
    -i /etc/lynx/lynx.cfg
cd ..
rm -rf lynx2.8.9rel.1


tar -xf pciutils-3.10.0.tar.gz
cd pciutils-3.10.0
make PREFIX=/usr                \
     SHAREDIR=/usr/share/hwdata \
     SHARED=yes
sudo make PREFIX=/usr                \
     SHAREDIR=/usr/share/hwdata \
     SHARED=yes                 \
     install install-lib        &&
sudo chmod -v 755 /usr/lib/libpci.so
sudo update-pciids
cd ..
rm -rf pciutils-3.10.0

# Firmware tools installed


# Install file system

## Kernel configuration
tar -xf dosfstools-4.2.tar.gz
cd dosfstools-4.2
./configure --prefix=/usr            \
            --enable-compat-symlinks \
            --mandir=/usr/share/man  \
            --docdir=/usr/share/doc/dosfstools-4.2 &&
make
make check
sudo make install
cd ..
rm -rf dosfstools-4.2

# File system installed
