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
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j$(nproc)
export SYS_TRIPLET=/usr/bin/gcc -dumpmachine
EOF

source ~/.bash_profile
}

eal.setup.toolchain() {
    echo -e "I: The detected system triplet is $(/usr/bin/gcc -dumpmachine)."
    export SYS_TRIPLET=$(/usr/bin/gcc -dumpmachine)
    echo 
}

main