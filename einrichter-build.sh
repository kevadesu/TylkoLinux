#!/bin/bash

function eal.debug.buildBash() {
    EIR_PKG=bash
    pushd $LFS/sources/bash
        eal.notification.buildconf
        ./configure --prefix=/usr                      \
                    --build=$(sh support/config.guess)  \
                    --host=$LFS_TGT                      \
                    --without-bash-malloc || eal.kill "At bash - compilation configuration"
        eal.notification.compiling
        make || eal.kill "At bash - compilation"
        eal.notification.installing
        make DESTDIR=$LFS install || eal.kill "At bash - installation"
        ln -sv bash $LFS/bin/sh
    popd
}

main() {
    read -p "Attempting to modify installation at $LFS. Is this correct? (y/n): " WOPT
    case "$WOPT" in
        y|Y)
            echo "OK!"
        ;;
        *)
            exit 1
        ;;
    esac
    echo "Einrichter is designed to work as an install script where you can resume where you left off. Do NOT skip anything if you have not ran the step yet. Type R to run, S to skip and Q to quit."
    read -p "Pending step: Extracting packages. Run, skip or quit?" OPT
    case "$OPT" in
        R)
            eal.setup.xr
            ;;
        S)
            echo "Step skipped."
            ;;
        Q)
            exit
            ;;
        *)
            echo "Unknown command. Repeating questions."
            ;;
    esac
    read -p "Pending step: Setting up environment. Run, skip or quit?" OPT
    case "$OPT" in
        R)
            eal.setup.env
            ;;
        S)
            echo "Step skipped."
            ;;
        Q)
            exit
            ;;
        *)
            echo "Unknown command. Repeating questions."
            ;;
    esac
    read -p "Pending step: Setting up toolchain. Run, skip or quit?" OPT
    case "$OPT" in
        R)
            eal.setup.toolchain
            ;;
        S)
            echo "Step skipped."
            ;;
        Q)
            exit
            ;;
        *)
            echo "Unknown command. Repeating questions."
            ;;
    esac
    read -p "Pending step: Installing cross toolchain and packages. Run, skip or quit?" OPT
    case "$OPT" in
        R)
            eal.install.toolchain
            ;;
        S)
            echo "Step skipped."
            ;;
        Q)
            exit
            ;;
        *)
            echo "Unknown command. Repeating questions."
            ;;
    esac
    read -p "Pending step: Verifying installation. Run, skip or quit?" OPT
    case "$OPT" in
        R)
            eal.install.verify
            ;;
        S)
            echo "Step skipped."
            ;;
        Q)
            exit
            ;;
        *)
            echo "Unknown command. Repeating questions."
            ;;
    esac
    echo "Done!"
    exit
}

function eal.setup.xr() {
    echo "[i] Extracting and renaming ALL packages..."
    sleep 0.5
    pushd $LFS/sources/ || bail "\$LFS/sources/ does not eixst."
        tar -xvf gcc-14.2.0.tar.xz || eal.kill "Failed to extract GCC"
        mv -v gcc-14.2.0 gcc
        pushd $LFS/sources/gcc || eal.kill "Failed to enter GCC source tree"
            tar -xf ../mpfr-4.2.1.tar.xz || eal.kill "Failed to extract MPFR"
            mv -v mpfr-4.2.1 mpfr 
            tar -xf ../gmp-6.3.0.tar.xz || eal.kill "Failed to extract GMP"
            mv -v gmp-6.3.0 gmp
            tar -xf ../mpc-1.3.1.tar.gz || eal.kill "Failed to extract MPC"
            mv -v mpc-1.3.1 mpc
        # shellcheck disable=SC2164
        popd
        tar -xvf "$LFS"/sources/binutils-2.43.1.tar.xz
        mv binutils-2.43.1 binutils
        tar -xvf linux-6.10.5.tar.xz
        mv -v linux-6.10.5 linux
        tar -xvf glibc-2.40.tar.xz
        mv -v glibc-2.40 glibc
        tar -xvf coreutils-9.5.tar.xz
        mv coreutils-9.5 coreutils
        tar -xvf diffutils-3.10.tar.xz
        mv diffutils-3.10 diffutils
        tar -xvf file-5.45.tar.gz
        mv file-5.45 file
        tar -xvf m4-1.4.19.tar.xz
        mv m4-1.4.19 m4
        tar -xvf ncurses-6.5.tar.gz
        mv ncurses-6.5 ncurses
        tar -xvf bash-5.2.32.tar.gz
        mv bash-5.2.32 bash
        tar -xvf findutils-4.10.0.tar.xz
        mv findutils-4.10.0 findutils
        tar -xvf gawk-5.3.0.tar.*z
        mv gawk-5.3.0 gawk
        tar -xvf grep-3.11.tar.*z
        mv grep-3.11 grep
        tar -xvf gzip-1.13.tar.*z
        mv gzip-1.13 gzip
        tar -xvf make-4.4.1.tar.*z
        mv make-4.4.1 make
        tar -xvf patch-2.7.6.tar.*z
        mv patch-2.7.6 patch
        tar -xvf sed-4.9.tar.*z
        mv sed-4.9 sed
        tar -xvf tar-1.35*
        mv tar-1.35 tar
        tar -xvf xz-5.6.2.tar.*z
        mv xz-5.6.2 xz
        tar -xvf gettext*xz
        mv gettext-0.22.5 gettext
        tar -xvf bison*xz
        mv bison-3.8.2 bison
        tar -xvf perl*xz
        mv perl-5.40.0 perl
        tar -xvf Python*xz
        mv Python-3.12.5 python
        tar -xvf texinfo*xz
        mv texinfo-7.1 texinfo
        tar -xvf util-linux*.xz
        mv util-linux-2.40.2 util-linux
        tar -xvf man-pages-6.9.1.tar.xz
        mv man-pages-6.9.1.tar.xz man-pages
        tar -xvf iana-etc-20240806.tar.gz
        tar -xvf zlib-1.3.1.tar.gz
        mv zlib-1.3.1 zlib
        tar -xvf bzip2-1.0.8.tar.gz
        mv bzip2-1.0.8 bzip2
        tar -xvf lz4-1.10.0.tar.gz
        mv lz4-1.10.0 lz4
        tar -xvf zstd-1.5.6.tar.gz
        mv zstd-1.5.6 zstd
        tar -xvf readline-8.2.13.tar.gz
        mv readline-8.2.13 readline
        tar -xvf bc-6.7.6.tar.xz
        mv bc-6.7.6 bc
        tar -xvf flex-2.6.4.tar.gz
        mv flex-2.6.4 flex
        tar -xvf tcl8.6.14-src.tar.gz
        mv tcl8.6.14 tcl
        tar -xvf expect5.45.4.tar.gz
        mv expect5.45.4 expect
        tar -xvf dejagnu-1.6.3.tar.gz
        mv dejagnu-1.6.3 dejagnu
        tar -xvf pkgconf-2.3.0.tar.xz
        mv pkgconf-2.3.0 pkgconf
        tar -xvf gmp-6.3.0.tar.xz
        mv gmp-6.3.0 gmp
        tar -xvf mpfr-4.2.1.tar.xz
        mv mpfr-4.2.1 mpfr
        tar -xvf mpc-1.3.1.tar.gz
        mv mpc-1.3.1 mpc
        tar -xvf attr-2.5.2.tar.gz
        mv attr-2.5.2 attr
        tar -xvf acl-2.3.2.tar.xz
        mv acl-2.3.2 acl
        tar -xvf libcap-2.70.tar.xz 
        mv libcap-2.70 libcap
        tar -xvf libxcrypt-4.4.36.tar.xz
        mv libxcrypt-4.4.36 libxcrypt
        tar -xvf shadow-4.16.0.tar.xz
        mv shadow-4.16.0 shadow
        tar -xvf psmisc-23.7.tar.xz
        mv psmisc-23.7 psmisc
        tar -xvf libtool-2.4.7.tar.xz
        mv libtool-2.4.7 libtool
        tar -xvf gdbm-1.24.tar.gz 
        mv gdbm-1.24 gdbm
        tar -xvf gperf-3.1.tar.gz; 
        mv gperf-3.1 gperf
        tar -xvf expat-2.6.4.tar.xz; 
        mv expat-2.6.4 expat
        tar -xvf inetutils-2.5.tar.xz 
        mv inetutils-2.5 inetutils
        tar -xvf less-661.tar.gz; 
        mv less-661 less
        tar -xvf XML-Parser-2.47.tar.gz; 
        mv XML-Parser-2.47 XML-Parser
        tar -xvf intltool-0.51.0.tar.gz; 
        mv intltool-0.51.0 intltool
        tar -xvf autoconf-2.72.tar.xz; 
        tar -xvf automake-1.17.tar.xz; 
        mv autoconf-2.72 autoconf; 
        mv automake-1.17 automake
        tar -xvf openssl-3.3.1.tar.gz; 
        mv openssl-3.3.1 openssl
        tar -xvf kmod-33.tar.xz; 
        mv kmod-33 kmod
        tar -xvf elfutils-0.191.tar.bz2; 
        mv elfutils-0.191 elfutils
        tar -xvf libffi-3.4.6.tar.gz; 
        mv libffi-3.4.6 libffi
        tar -xvf flit_core-3.9.0.tar.gz; 
        mv flit_core-3.9.0 flit_core
        tar -xvf wheel-0.44.0.tar.gz; 
        mv wheel-0.44.0 wheel
        tar -xvf setuptools-72.2.0.tar.gz; 
        mv setuptools-72.2.0 setuptools
        tar -xvf ninja-1.12.1.tar.gz; 
        mv ninja-1.12.1 ninja
	tar -xvf meson-1.5.1.tar.gz; 
	mv meson-1.5.1 meson
	tar -xvf check-0.15.2.tar.gz; 
	mv check-0.15.2 check
        tar -xvf groff-1.23.0.tar.gz; 
        mv groff-1.23.0 groff
        tar -xvf grub-2.12.tar.xz; 
        mv grub-2.12 grub
        tar -xvf iproute2-6.10.0.tar.xz; 
        mv iproute2-6.10.0 iproute2
        tar -xvf kbd-2.6.4.tar.xz; 
        mv kbd-2.6.4 kbd
        tar -xvf libpipeline-1.5.7.tar.gz; 
        mv libpipeline-1.5.7 libpipeline
        tar -xvf nano-8.1.tar.xz; 
        mv nano-8.1 nano
        tar -xvf MarkupSafe-2.1.5.tar.gz; 
        mv MarkupSafe-2.1.5 MarkupSafe
        tar -xvf jinja2-3.1.4.tar.gz; 
        mv jinja2-3.1.4 jinja
        tar -xvf systemd-256.4.tar.gz; 
        mv systemd-256.4 systemd
        tar -xvf dbus-1.14.10.tar.xz; 
        mv dbus-1.14.10 dbus
        tar -xvf man-db-2.12.1.tar.xz; 
        mv man-db-2.12.1 man-db
        tar -xvf procps-ng-4.0.4.tar.xz; 
        mv procps-ng-4.0.4 procps-ng
        tar -xvf e2fsprogs-1.47.1.tar.gz; 
        mv e2fsprogs-1.47.1 e2fsprogs
        tar -xvf git-2.48.1.tar.xz
        mv git-2.48.1 git
        tar -xvf wget-1.24.5.tar.gz
        mv wget-1.24.5 wget
        tar -xvf p11-kit-0.25.5.tar.xz
        mv p11-kit-0.25.5 p11-kit
        tar -xvf make-ca-1.14.tar.gz
        mv make-ca-1.14 make-ca
        tar -xvf libtasn1-4.19.0.tar.gz
        mv libtasn1-4.19.0 libtasn1
        tar -xvf cpio-2.15.tar.bz2
        mv cpio-2.15 cpio
        tar -xvf hwdata-0.385.tar.gz
        mv hwdata-0.385 hwdata
        tar -xvf pciutils-3.13.0.tar.gz
        mv pciutils-3.13.0 pciutils
        tar -xvf libgpg-error-1.50.tar.bz2
        mv libgpg-error-1.50 libgpg-error
        tar -xvf libassuan-3.0.1.tar.bz2
        mv libassuan-3.0.1 libassaun
        tar -xvf gpgme-1.23.2.tar.bz2
        mv gpgme-1.23.2 gpgme
}

function eal.setup.env() {
    echo "The installer is about to begin setting up the environment. Please wait..."
    sleep 2
    read -p "[i] Specify the path to the target LFS installation: " LFS
    cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

    echo -e "
set +h
umask 022
LFS=${LFS}
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
MAKEFLAGS=-j$(nproc)
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE MAKEFLAGS 
" > ~/.bashrc

    source $HOME/.bash_profile
}

function eal.notification.buildconf() {
    echo "I: -- The installer is now configuring the build options --" && sleep 0.2
    }
function eal.notification.compiling() {
    echo "I: -- The installer is now compiling the package $EIR_PKG --" && sleep 0.2
}
function eal.notification.installing() {
    echo "I: -- The installer is now installing the package $EIR_PKG --" && sleep 0.2
}
function eal.notification.extracting() {
#   echo "I: -- The installer is now extracting the necessary archives for $EIR_PKG --" && sleep 0.2
    echo "I: -- Assumes package is already extracted. --"
}
function eal.emergencyAlert() {
    echo -e "\a" && sleep 0.1 && echo -e "\07" && sleep 0.1 && tput bel
}

function eal.setup.toolchain() {
    echo -e "I: The detected system triplet is $(/usr/bin/gcc -dumpmachine)."
    export LFS_TGT=$(/usr/bin/gcc -dumpmachine)
    cd $LFS/sources/
    EIR_PKG=binutils
    eal.notification.extracting
    sleep 0.5
    pushd $LFS/sources/binutils/
        mkdir -v build
        cd       build
        eal.notification.buildconf
        sleep 0.5
	../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu || eal.kill "At configuring compilation"
        eal.notification.compiling
        make || eal.kill "At compiling Binutils"
        eal.notification.installing
        make install
    popd
    eal.notification.extracting
    pushd $LFS/sources/
        pushd $LFS/sources/gcc/
            case $(uname -m) in
                x86_64)
                    sed -e '/m64=/s/lib64/lib/' \
                    -i.orig gcc/config/i386/t-linux64
            ;;
            esac
            mkdir -v build
            cd       build
            eal.notification.buildconf
            ../configure                  \
                --target=$LFS_TGT         \
                --prefix=$LFS/tools       \
                --with-glibc-version=2.40 \
                --with-sysroot=$LFS       \
                --with-newlib             \
                --without-headers         \
                --enable-default-pie      \
                --enable-default-ssp      \
                --disable-nls             \
                --disable-shared          \
                --disable-multilib        \
                --disable-threads         \
                --disable-libatomic       \
                --disable-libgomp         \
                --disable-libquadmath     \
                --disable-libssp          \
                --disable-libvtv          \
                --disable-libstdcxx       \
                --enable-languages=c,c++
            eal.notification.compiling
            make || eal.kill "At GCC - Pass 1"
            eal.notification.installing
            make install
            cd ..
            cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
                `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
        popd
        EIR_PKG=linux
        eal.notification.extracting
        pushd $LFS/sources/linux/
            make mrproper
            make headers
            find usr/include -type f ! -name '*.h' -delete
            cp -rv usr/include $LFS/usr
        popd
        EIR_PKG=glibc
        eal.notification.extracting
        pushd $LFS/sources/glibc/
            echo -e "I: -- The installer is creating a symbolic link for LSB compliance. Depending on architecture, it may also create a compatibility symbolic link for proper operation of the dynamic library loader. --"
            case $(uname -m) in
                i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
                ;;
                x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
                        ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
                ;;
            esac
            echo -e "I: -- The installer is now patching glibc. --"
            patch -Np1 -i ../glibc-2.40-fhs-1.patch
            mkdir -v build
            cd       build
            echo "rootsbindir=/usr/sbin" > configparms
            eal.notification.buildconf
            ../configure                           \
                --prefix=/usr                       \
                --host=$LFS_TGT                      \
                --build=$(../scripts/config.guess)    \
                --enable-kernel=4.19                   \
                --with-headers=$LFS/usr/include         \
                --disable-nscd                           \
                libc_cv_slibdir=/usr/lib
            eal.notification.compiling
            make
            eal.emergencyAlert
            echo -e "\033[0;31mW: -- Before installing the package, make sure that the variable LFS is CORRECTLY SET to have the value of the target LFS system. If it doesn't, and you're running this script as root, despite the recommendations, this will install the newly built glibc to the HOST SYSTEM, rendering it almost certainly unusable. Please make sure that this variable is correctly set: --"
            echo -e "\$LFS: ${LFS}"
            echo -e "If this is incorrect, exit the installer immediately by pressing CTRL + C, wipe the target LFS partition and restart the entire installation process. If the variable is correct, press Enter"
            read
            eal.notification.installing
            make DESTDIR=$LFS install
            sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
            echo "I: -- The next output you'll receive needs to start with \"[Requesting program interpreter:\". If the output is not similar to this, or not shown at all, something is wrong. Please confirm that there is an output by pressing enter. If the output is wrong, type \"R\" without the quotation marks to drop into the shell. --"
            echo 'int main(){}' | $LFS_TGT-gcc -xc -
            readelf -l a.out | grep ld-linux
            read -p "->" TEMP_OUTPUT
            case "$TEMP_OUTPUT" in
                R)
                    echo "Fix issues by checking the LFS 12.2-systemd book. Once you fixed everything, clean up the test file by running \"rm -v a.out\"."
                    sh
                ;;
                *)
                    echo "OK"
                ;;
            esac
            rm -v a.out
        popd
        pushd $LFS/sources/gcc/
            mkdir -v build-libstdcpp
            cd       build-libstdcpp
            EIR_PKG=libstdcpp
            eal.notification.buildconf
            ../libstdc++-v3/configure           \
                --host=$LFS_TGT                  \
                --build=$(../config.guess)        \
                --prefix=/usr                      \
                --disable-multilib                  \
                --disable-nls                        \
                --disable-libstdcxx-pch               \
                --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
            rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
        popd
    popd
}

eal.kill() {
    echo "KILL! | $1 | Quitting."
    exit 1
}

function eal.install.toolchain() {
    pushd $LFS/sources/
        EIR_PKG=M4
        pushd $LFS/sources/m4/
            eal.notification.buildconf
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT \
                        --build=$(build-aux/config.guess)
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
        popd
        EIR_PKG=ncurses
        pushd $LFS/sources/ncurses
            sed -i s/mawk// configure
            mkdir build
            pushd build
                ../configure AWK=gawk
                make -C include || eal.kill "At ncurses - command \"make -C include\""
                make -C progs tic || eal.kill "At ncurses - command \"make -C progs tic\""
            popd
            eal.notification.buildconf
            ./configure --prefix=/usr                \
                        --host=$LFS_TGT              \
                        --build=$(./config.guess)    \
                        --mandir=/usr/share/man      \
                        --with-manpage-format=normal \
                        --with-shared                \
                        --without-normal             \
                        --with-cxx-shared            \
                        --without-debug              \
                        --without-ada                \
                        --disable-stripping || eal.kill "At ncurses - compilation configuration"
            eal.notification.compiling
            make || eal.kill "At ncurses - compilation"
            eal.notification.installing
            make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install || eal.kill "At ncurses - installation"
            ln -sv lib/libncursesw.so $LFS/usr/lib/libncurses.so
            sed -e 's/^#if.*XOPEN.*$/#if 1/' \
               -i $LFS/usr/include/curses.h
        popd
        EIR_PKG=bash
        pushd $LFS/sources/bash
            eal.notification.buildconf
            ./configure --prefix=/usr                      \
                        --build=$(sh support/config.guess)  \
                        --host=$LFS_TGT                      \
                        --without-bash-malloc || eal.kill "At bash - compilation configuration"
            eal.notification.compiling
            make || eal.kill "At ncurses - compilation"
            eal.notification.installing
            make DESTDIR=$LFS install || eal.kill "At bash - installation"
            ln -sv bash $LFS/bin/sh
        popd
        EIR_PKG=coreutils
        eal.notification.extracting
        pushd $LFS/sources/coreutils
            eal.notification.buildconf
            ./configure --prefix=/usr                     \
                        --host=$LFS_TGT                    \
                        --build=$(build-aux/config.guess)   \
                        --enable-install-program=hostname    \
                        --enable-no-install-program=kill,uptime
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
            mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
            mkdir -pv $LFS/usr/share/man/man8
            mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
            sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8
        popd
        EIR_PKG=diffutils
        echo "Install notifications will not be shown for small packages, as it will be obvious which action will be executed." && sleep 10
        pushd $LFS/sources/diffutils
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(./build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        pushd $LFS/sources/file
            mkdir build
            pushd build
                ../configure --disable-bzlib      \
                            --disable-libseccomp   \
                            --disable-xzlib         \
                            --disable-zlib
                make
            popd
            ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
            make FILE_COMPILE=$(pwd)/build/src/file
            make DESTDIR=$LFS install
            rm -v $LFS/usr/lib/libmagic.la
        popd
        pushd $LFS/sources/findutils
            ./configure --prefix=/usr                   \
                        --localstatedir=/var/lib/locate  \
                        --host=$LFS_TGT                   \
                        --build=$(build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        pushd $LFS/sources/gawk
            sed -i 's/extras//' Makefile.in
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        pushd $LFS/sources/grep
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(./build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        pushd $LFS/sources/gzip
            ./configure --prefix=/usr --host=$LFS_TGT
            make
            make DESTDIR=$LFS install
        popd
        pushd $LFS/sources/make
            ./configure --prefix=/usr   \
                        --without-guile  \
                        --host=$LFS_TGT   \
                        --build=$(build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        pushd $LFS/sources/patch
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        # From here on I got lazy with the script to get it over with Chapter 6 faster, I'll fix all of this when TylkoLinux is in last Beta stage
        # Update: DON'T GET LAZY WITH THE SCRIPT!!! SPECIFY THE FULL FUCKING DIRECTORY NAME!!! THIS FUCKING CREATED COMMAND NOT FOUND ERRORS
        pushd $LFS/sources/sed
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(./build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        pushd $LFS/sources/tar
            ./configure --prefix=/usr                     \
                        --host=$LFS_TGT                    \
                        --build=$(build-aux/config.guess) 
            make
            make DESTDIR=$LFS install
        popd
        pushd $LFS/sources/xz
            ./configure --prefix=/usr                     \
                        --host=$LFS_TGT                    \
                        --build=$(build-aux/config.guess)   \
                        --disable-static                     \
                        --docdir=/usr/share/doc/xz-5.6.2
            make
            make DESTDIR=$LFS install
            rm -v $LFS/usr/lib/liblzma.la
        popd
        pushd $LFS/sources/binutils
            sed '6009s/$add_dir//' -i ltmain.sh
            rm -rf build
            mkdir -v build
            cd       build
            ../configure                   \
                --prefix=/usr               \
                --build=$(../config.guess)   \
                --host=$LFS_TGT               \
                --disable-nls                  \
                --enable-shared                 \
                --enable-gprofng=no              \
                --disable-werror                  \
                --enable-64-bit-bfd                \
                --enable-new-dtags                  \
                --enable-default-hash-style=gnu
            make
            make DESTDIR=$LFS install
            rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
        popd
        EIR_PKG=GCC
        pushd $LFS/sources/gcc
            case $(uname -m) in
                x86_64)
                    sed -e '/m64=/s/lib64/lib/' \
                        -i.orig gcc/config/i386/t-linux64
                ;;
            esac
            sed '/thread_header =/s/@.*@/gthr-posix.h/' \
                -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
            rm -rf build
            mkdir -v build            
            cd       build
            eal.notification.buildconf
            ../configure                                       \
                --build=$(../config.guess)                      \
                --host=$LFS_TGT                                  \
                --target=$LFS_TGT                                 \
                LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc          \
                --prefix=/usr                                       \
                --with-build-sysroot=$LFS                            \
                --enable-default-pie                                  \
                --enable-default-ssp                                   \
                --disable-nls                                           \
                --disable-multilib                                       \
                --disable-libatomic                                       \
                --disable-libgomp                                          \
                --disable-libquadmath                                       \
                --disable-libsanitizer                                       \
                --disable-libssp                                              \
                --disable-libvtv                                               \
                --enable-languages=c,c++
            eal.notification.compiling
            make || eal.kill "At GCC - Pass 2"
            eal.notification.installing
            make DESTDIR=$LFS install || eal.kill "At GCC - Pass 2 - Installation"
            ln -sv gcc $LFS/usr/bin/cc
        popd
    popd
    echo "Cross-Toolchain installation has completed."
}

function eal.install.verify() {
    ver_check Binutils       $LFS/bin/ld                   2.43.1
    ver_check GCC            $LGS/bin/gcc                  14.2.0
    ver_check Glibc          $LFS/bin/ldd                  2.40
    ver_check M4             $LFS/bin/m4                   1.4.19
    ver_check Ncurses        $LFS/bin/ncursesw6-config     6.5
    ver_check Bash           $LFS/bin/bash                 5.2.32
    ver_check Coreutils      $LFS/bin/touch                9.5
    ver_check Diffutils      $LFS/bin/cmp                  3.10
    ver_check File           $LFS/bin/file                 5.45
    ver_check Findutils      $LFS/bin/find                 4.10.0
    ver_check Gawk           $LFS/bin/gawk                 5.3.0
    ver_check Grep           $LFS/bin/grep                 3.11
    ver_check Gzip           $LFS/bin/gzip                 1.13
    ver_check Make           $LFS/bin/make                 4.4.1
    ver_check Patch          $LFS/bin/patch                2.7.6
    ver_check Sed            $LFS/bin/sed                  4.9
    ver_check Tar            $LFS/bin/tar                  1.35
    ver_check Xz             $LFS/bin/xz                   5.6.2
}

ver_check()
{
   if ! type -p $2 &>/dev/null
   then 
     echo -e "${BRed}ERROR ${Color_Off}| Cannot find $2 ($1)"; return 1; 
   fi
   v=$($2 --version 2>&1 | grep -E -o '[0-9]+\.[0-9\.]+[a-z]*' | head -n1)
   if printf '%s\n' "$3" "$v" | sort --version-sort --check &>/dev/null
   then 
     printf "${BGreen}OK    ${Color_Off}| %-9s %-6s >= $3\n" "$1" "$v"; return 0;
   else 
     printf "${BRed}ERROR ${Color_Off}| %-9s is TOO OLD ($3 or later required)\n" "$1"; 
     return 1; 
   fi
}

bail() { echo -e "${BRed}FATAL ${Color_Off}| $1"; exit 1; }

case "$@" in
    debug.buildBash)
        eal.debug.buildBash
    ;;
    *)
        main
    ;;
esac
