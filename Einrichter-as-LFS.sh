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

function eal.setup.toolchain() {
    echo -e "I: The detected system triplet is $(/usr/bin/gcc -dumpmachine)."
    export LFS_TGT=$(/usr/bin/gcc -dumpmachine)
    echo 
}

function eal.install.cross-binutils() {
    cd $LFS/sources/
    echo -e "I: -- The installer is now extracting binutils --"
    sleep 0.5
    tar -xvf $LFS/sources/binutils-2.43.1.tar.xz
    cd $LFS/sources/binutils-2.43.1/
    mkdir -v build
    cd       build
    echo -e "I: -- The installer is now configuring build options --"
    sleep 0.5
    ../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu
    echo -e "I: -- The installer is now compiling the package --"
    make
    echo -e "I: -- The installer is now installing the package --"
    make install

}
main