#!/bin/bash

main() {
    eal.setup.env
    eal.setup.toolchain
}

function eal.setup.env() {
    echo "The installer is about to begin setting up the environment. Please wait..."
    sleep 2

    cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

    cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
MAKEFLAGS=-j$(nproc)
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE MAKEFLAGS 
EOF

source ~/.bash_profile
}

function eal.notification.buildconf() {echo "I: -- The installer is now configuring the build options --" && sleep 0.2}
function eal.notification.compiling() {echo "I: -- The installer is now compiling the package $EIR_PKG --" && sleep 0.2}
function eal.notification.installing() {echo "I: -- The installer is now installing the package $EIR_PKG --" && sleep 0.2}
function eal.notification.extracting() {echo "I: -- The installer is now extracting the necessary archives for $EIR_PKG --" && sleep 0.2}
function eal.emergencyAlert() {echo -e "\a" && sleep 0.1 && echo -e "\07" && sleep 0.1 && tput bel}

function eal.setup.toolchain() {
    echo -e "I: The detected system triplet is $(/usr/bin/gcc -dumpmachine)."
    export LFS_TGT=$(/usr/bin/gcc -dumpmachine)
    echo 
}

function eal.install.cross-toolchain() {
    cd $LFS/sources/
    EIR_PKG=binutils
    eal.notification.extracting
    sleep 0.5
    tar -xvf $LFS/sources/binutils-2.43.1.tar.xz
    cd $LFS/sources/binutils-2.43.1/
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
             --enable-default-hash-style=gnu
    eal.notification.compiling
    make
    eal.notification.installing
    make install
    eal.notification.extracting
    pushd $LFS/sources/
        tar -xvf gcc-14.2.0.tar.xz 
        mv -v gcc-14.2.0 gcc
        pushd $LFS/sources/gcc/
            tar -xf ../mpfr-4.2.1.tar.xz
            mv -v mpfr-4.2.1 mpfr
            tar -xf ../gmp-6.3.0.tar.xz
            mv -v gmp-6.3.0 gmp
            tar -xf ../mpc-1.3.1.tar.gz
            mv -v mpc-1.3.1 mpc
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
            make
            eal.notification.installing
            make install
        popd
        EIR_PKG=linux
        eal.notification.extracting
        tar -xvf linux-6.10.5.tar.xz
        mv -v linux-6.10.5 linux
        pushd $LFS/sources/linux/
            make mrproper
            make headers
            find usr/include -type f ! -name '*.h' -delete
            cp -rv usr/include $LFS/usr
        popd
        EIR_PKG=glibc
        eal.notification.extracting
        tar -xvf glibc-2.40.tar.xz
        mv -v glibc-2.40 glibc
        echo -e "I: -- The installer is creating a symbolic link for LSB compliance. Depending on architecture, it may also create a compatibility symbolic link for proper operation of the dynamic library loader. --"
        case $(uname -m) in
            i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
            ;;
            x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
                    ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
            ;;
        esac
        pushd $LFS/sources/glibc/
            echo -e "I: -- The installer is now patching glibc. --"
            mkdir -v build
            cd       build
            echo "rootsbindir=/usr/sbin" > configparms
            eal.notification.buildconf
            ../configure                           \
                --prefix=/usr                      \
                --host=$LFS_TGT                    \
                --build=$(../scripts/config.guess) \
                --enable-kernel=4.19               \
                --with-headers=$LFS/usr/include    \
                --disable-nscd                     \
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
        popd
        pushd $LFS/sources/gcc/
            mkdir -v build
            cd       build
            EIR_PKG=libstdcpp
            eal.notification.buildconf
            ../libstdc++-v3/configure           \
                --host=$LFS_TGT                 \
                --build=$(../config.guess)      \
                --prefix=/usr                   \
                --disable-multilib              \
                --disable-nls                   \
                --disable-libstdcxx-pch         \
                --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
            rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
        popd
        EIR_PKG=M4
        tar -xvf m4-1.4.19.tar.xz
        mv m4-1.4.19 m4
        pushd $LFS/sources/m4/
            eal.notification.buildconf
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT \
                        --build=$(build-aux/config.guess)
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
}       

main