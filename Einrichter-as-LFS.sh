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
}
main